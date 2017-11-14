module Relay
  module IO
    class Peer < Concurrent::Actor::RestartingContext
      include Algebrick::Matching
      include Algebrick::Types

      module Status
        DISCONNECTED = 1
        INITIALIZING = 2
        CONNECTED = 3
      end
      Algebrick.type do
        variants NewConnection = type { fields! remote_node_id: String, address: String, new_channel_opt: Hash },
        HandshakeCompleted = type { fields! connection: EM::Connection },
        Timeout = atom,
        Event = type { fields! message_type: Object, data: Object, conn: Object }
      end

      def initialize
        @status = Status::DISCONNECTED
        # @spawn = Peer.spawn("peer")
      end

      def on_message(message)
        puts @status
        # binding.pry
        puts "Peer#on_message #{message}"
        case @status
        when Status::DISCONNECTED
          match message,
            (on HandshakeCompleted.(~any) do |conn|
              puts "Peer::HandshakeCompleted #{conn}"
              @status = Status::CONNECTED
              conn.peer = self

              Concurrent::TimerTask.new(execution_interval: 3) do
                reference << Event[Timeout, {}, conn]
              end.execute
            end),
            (on Object do
              puts "status:#{@status}:#{message}"
            end)
        when Status::INITIALIZING
        when Status::CONNECTED
          match message,
            (on Event.(message_type: Timeout, data: Object, conn: ~any) do |conn|
              puts "Peer#on_message Timeout #{conn}"
              conn.send_message(::Relay::Wire::Ping.new(num_pong_bytes: 1, byteslen: 2, ignored: "\x00\x00"))
            end),
            (on Event.(message_type: ::Relay::Wire::MessageCodec::Ping, data: ~any, conn: ~any) do |ping, conn|
              puts "Peer#on_message Relay::Wire::MessageCodec::Ping #{ping} #{conn}"
              pong = Relay::Wire::Pong.new(byteslen: ping.num_pong_bytes, ignored: "\x00" * ping.num_pong_bytes)
              conn.send_message(pong)
            end),
            (on Event.(message_type: ::Relay::Wire::MessageCodec::Pong, data: ~any, conn: ~any) do |pong, conn|
              puts "Peer#on_message Relay::Wire::MessageCodec::Pong #{pong} #{conn}"
            end),
            (on Object do
              puts "status:#{@status}:#{message}"
            end)
        end
      end
    end
  end
end
