# frozen_string_literal: true

module Relay
  module Wire
    class Pong
      attr_reader :byteslen, :ignored

      def initialize(byteslen: 1, ignored: "\x00")
        @byteslen = byteslen
        @ignored = ignored
      end

      def self.load(payload)
        byteslen, rest = payload.unpack('Sa*')
        ignored = rest.byteslice(0, byteslen)
        return nil if rest.bytesize < byteslen
        ignored = rest.byteslice(0, byteslen)
        new(byteslen: byteslen, ignored: ignored)
      end

      def size
        2 + byteslen
      end

      def to_payload
        [::Relay::Wire::MessageTypes::PONG, byteslen, ignored].pack("S2a*")
      end
    end
  end
end
