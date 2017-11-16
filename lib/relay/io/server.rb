# frozen_string_literal: true

module Relay
  module IO
    class Server < EM::Connection
      include Relay::Wire::MessageCodec
      include Concurrent::Concern::Logging

      attr_accessor :peer

      def initialize(switchboard)
        @switchboard = switchboard
      end

      def post_init
        log(Logger::DEBUG, @switchboard.path, 'Relay::IO::Server#post_init')
        @handler = MessageHandler.new(self)
        @switchboard << HandshakeCompleted[self]
      end

      def receive_data(data)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Server#receive_data #{data.bth}")
        return if data.strip.empty?
        @handler.handle(data)
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Server#unbind #{reason}")
      end

      def send_message(message)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Server#send_message #{message}")
        send_data(message.to_payload)
      end
    end
  end
end
