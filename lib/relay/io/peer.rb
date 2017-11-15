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


      def initialize
        @status = Status::DISCONNECTED
      end

      def on_message(message)
        log(Logger::DEBUG, "status:#{@status}:#{message}")
        case @status
        when Status::DISCONNECTED
          match message, (on HandshakeCompleted.(~any) do |conn|
            @status = Status::CONNECTED
            conn.peer = self
            Concurrent::TimerTask.new(execution_interval: 60) do
              reference << Timeout[conn]
            end.execute if conn.is_a? ::Relay::IO::Client
          end), (on Object do
            log(Logger::WARN, "NO OP")
          end)
        when Status::INITIALIZING
        when Status::CONNECTED
          match message, (on Timeout.(~any) do |conn|
            log(Logger::DEBUG, "Peer#on_message Timeout #{conn}")
            conn.send_message(::Relay::Wire::Ping.new(num_pong_bytes: 1, byteslen: 2, ignored: "\x00\x00"))
          end), (on Event.(message_type: Ping, data: ~any, conn: ~any) do |ping, conn|
            log(Logger::DEBUG, "Peer#on_message Relay::Wire::MessageCodec::Ping #{ping} #{conn}")
            pong = Relay::Wire::Pong.new(byteslen: ping.num_pong_bytes, ignored: "\x00" * ping.num_pong_bytes)
            conn.send_message(pong)
          end), (on Event.(message_type: Pong, data: ~any, conn: ~any) do |pong, conn|
            log(Logger::DEBUG, "Peer#on_message Relay::Wire::MessageCodec::Pong #{pong} #{conn}")
          end), (on Object do
            log(Logger::WARN, "NO OP")
          end)
        end
      end
    end
  end
end
