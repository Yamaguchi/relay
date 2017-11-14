# frozen_string_literal: true

module Relay
  module Wire
    class Ping
      attr_reader :num_pong_bytes, :byteslen, :ignored

      def initialize(num_pong_bytes: 1, byteslen: 1, ignored: "\x00")
        @num_pong_bytes = num_pong_bytes
        @byteslen = byteslen
        @ignored = ignored
      end

      def self.load(payload)
        num_pong_bytes, byteslen, rest = payload.unpack('S2a*')
        return nil if rest.bytesize < byteslen
        ignored = rest.byteslice(0, byteslen)
        new(num_pong_bytes: num_pong_bytes, byteslen: byteslen, ignored: ignored)
      end

      def size
        4 + byteslen
      end

      def to_payload
        [::Relay::Wire::MessageTypes::PING, num_pong_bytes, byteslen, ignored].pack("S3a*")
      end
    end
  end
end
