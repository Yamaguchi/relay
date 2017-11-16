# frozen_string_literal: true

module Relay
  module IO
    class Client < EM::Connection
      include Relay::Wire::MessageCodec
      include Concurrent::Concern::Logging

      attr_accessor :peer

      def initialize(switchboard)
        @switchboard = switchboard
      end

      def post_init
        log(Logger::DEBUG, @switchboard.path, 'Relay::IO::Client#post_init')
        @handler = MessageHandler.new(self)
      end

      def connection_completed
        log(Logger::DEBUG, @switchboard.path, 'Relay::IO::Client#connection_completed')
        @switchboard << HandshakeCompleted[self]
      end

      def receive_data(data)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Client#receive_data #{data.bth}")
        return if data.strip.empty?
        @handler.handle(data)
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Client#unbind #{reason}")
      end

      def send_message(message)
        log(Logger::DEBUG, @switchboard.path, "Relay::IO::Client#send_message #{message}")
        send_data(message.to_payload)
      end
    end
  end
end
