# frozen_string_literal: true

module Relay
  module Utils
    module BinaryExtensions
      def bth
        unpack('H*')[0]
      end

      def htb
        [self].pack('H*')
      end
    end
    class ::String
      include Relay::Utils::BinaryExtensions
    end
  end
end