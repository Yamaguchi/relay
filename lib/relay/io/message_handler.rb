# frozen_string_literal: true

module Relay
  module IO
    class MessageHandler
      MESSAGE_TYPE_SIZE = 2
      def initialize(conn)
        @buffer = ''
        @conn = conn
      end

      def handle(data)
        handle_internal(data)
      end

      def handle_internal(data)
        @buffer += data
        type, payload = parse(@buffer)
        return unless type
        message, rest = handle_message(type, payload)
        return unless message
        @buffer = ''
        handle_internal(rest) if rest&.bytesize&.positive?
      end

      def parse(buffer)
        return if buffer.bytesize < MESSAGE_TYPE_SIZE
        type = buffer.unpack('S')[0]
        raise "error" unless supported_message_types.include?(type)
        payload = buffer.byteslice(MESSAGE_TYPE_SIZE, buffer.bytesize)
        [type, payload]
      end

      def handle_message(type, payload)
        case type
        when Relay::Wire::MessageTypes::PING then on_ping(payload)
        when Relay::Wire::MessageTypes::PONG then on_pong(payload)
        else nil
        end
      end

      def supported_message_types
        Relay::Wire::MessageTypes.constants.map { |c| Relay::Wire::MessageTypes.const_get(c) }
      end

      def on_ping(payload)
        ping = Relay::Wire::Ping.load(payload)
        rest = payload[ping.size..-1]

        @conn.peer << Relay::IO::Peer::Event[Relay::Wire::MessageCodec::Ping, ping, @conn]
        [ping, rest]
      end

      def on_pong(payload)
        pong = Relay::Wire::Pong.load(payload)
        rest = payload[ping.size..-1]

        @conn.peer << Relay::IO::Peer::Event[Relay::Wire::MessageCodec::Pong, pong, @conn]
        [ping, rest]
      end
    end
  end
end
