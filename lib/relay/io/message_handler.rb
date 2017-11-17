# frozen_string_literal: true

module Relay
  module IO
    class MessageHandler
      NODE_ID_SIZE = 32
      MESSAGE_TYPE_SIZE = 2
      def initialize(conn, host, port)
        @buffer = ''
        @conn = conn
        @host = host
        @port = port
      end

      def handle(data)
        handle_internal(data)
      end

      def handle_internal(data)
        @buffer += data
        type, payload, remote_node_id = parse(@buffer)
        return unless type
        message, rest = handle_message(type, payload)
        return unless message
        @conn << Relay::Wire::MessageCodec::Received[remote_node_id, message, @host, @port]
        @buffer = ''
        handle_internal(rest) if rest&.bytesize&.positive?
      end

      def parse(buffer)
        return if buffer.bytesize < NODE_ID_SIZE + MESSAGE_TYPE_SIZE
        remote_node_id, type, = buffer.unpack('H64Sa*')
        raise 'error' unless supported_message_types.include?(type)
        payload = buffer.byteslice(NODE_ID_SIZE + MESSAGE_TYPE_SIZE, buffer.bytesize)
        [type, payload, remote_node_id]
      end

      def handle_message(type, payload)
        case type
        when Relay::Wire::MessageTypes::PING then on_ping(payload)
        when Relay::Wire::MessageTypes::PONG then on_pong(payload)
        end
      end

      def supported_message_types
        Relay::Wire::MessageTypes.constants.map { |c| Relay::Wire::MessageTypes.const_get(c) }
      end

      def on_ping(payload)
        ping = Relay::Wire::Ping.load(payload)
        rest = payload[ping.size..-1]
        [Relay::Wire::MessageCodec::Ping[ping], rest]
      end

      def on_pong(payload)
        pong = Relay::Wire::Pong.load(payload)
        rest = payload[pong.size..-1]
        [Relay::Wire::MessageCodec::Pong[pong], rest]
      end
    end
  end
end
