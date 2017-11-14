# frozen_string_literal: true

module Relay
  module IO
    class Client < EM::Connection

      attr_accessor :peer

      def initialize(switchboard)
        @switchboard = switchboard
      end

      def post_init
        puts "Relay::IO::Client#post_init"
      end

      def connection_completed
        puts "Relay::IO::Client#connection_completed"
        @switchboard << Relay::IO::Switchboard::HandshakeCompleted[self]
      end

      def receive_data(data)
        puts "Relay::IO::Client#receive_data #{data.unpack("H*")}"
      end

      def unbind(reason = nil)
        puts "Relay::IO::Client#unbind #{reason}"
      end

      def send_message(message)
        puts "Relay::IO::Client#send_message #{message.to_payload}"
        send_data(message.to_payload)
      end
    end
  end
end
