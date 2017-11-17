# frozen_string_literal: true

module Relay
  module IO
    class Peer < Concurrent::Actor::RestartingContext
      include Algebrick::Matching
      include Relay::Wire::MessageCodec

      module Status
        DISCONNECTED = 1
        INITIALIZING = 2
        CONNECTED = 3
      end

      def initialize(host)
        @status = Status::DISCONNECTED
        @host = host
      end

      def on_message(message)
        log(Logger::DEBUG, "status:#{@status}:#{message}")
        case @status
        when Status::DISCONNECTED
          match message, (on HandshakeCompleted.(~any, ~any, any, any) do |remote_node_id, conn|
            if conn.is_a? ::Relay::IO::Client
              Concurrent::TimerTask.new(execution_interval: 6) do
                reference << Timeout[conn]
              end.execute
            end
            @remote_node_id = remote_node_id
            @status = Status::CONNECTED
          end), (on any do
            log(Logger::WARN, 'NO OP')
          end)
        when Status::CONNECTED
          match message, (on Timeout.(~any) do |conn|
            log(Logger::DEBUG, "Peer#on_message Timeout #{conn}")
            ping = ::Relay::Wire::Ping.new(num_pong_bytes: 1, byteslen: 2, ignored: "\x00\x00")
            conn << Ping[ping]
          end), (on Event.(message_type: Ping.(~any), remote_node_id: any, conn: ~any) do |ping, conn|
            log(Logger::DEBUG, "Peer#on_message Relay::Wire::MessageCodec::Ping #{ping} #{conn}")
            # TODO: A node receiving a `ping` message SHOULD fail the channels if it has received
            # significantly in excess of one `ping` per 30 seconds, otherwise if
            # `num_pong_bytes` is less than 65532 it MUST respond by sending a `pong` message
            # with `byteslen` equal to `num_pong_bytes`, otherwise it MUST ignore the `ping`.

            pong = Relay::Wire::Pong.new(byteslen: ping.num_pong_bytes, ignored: "\x00" * ping.num_pong_bytes)
            conn << Pong[pong]
          end), (on Event.(message_type: Pong.(~any), remote_node_id: any, conn: ~any) do |pong, conn|
            log(Logger::DEBUG, "Peer#on_message Relay::Wire::MessageCodec::Pong #{pong} #{conn}")
            # TODO: A node receiving a `pong` message MAY fail the channels if `byteslen` does not
            # correspond to any `ping` `num_pong_bytes` value it has sent.
          end), (on any do
            log(Logger::WARN, 'NO OP')
          end)
        end
        match message, (on :host do
          @host
        end), (on :remote_node_id do
          @remote_node_id
        end), (on any)
      end

    end
  end
end
