# frozen_string_literal: true

require 'socket'

module Relay
  module IO
    class Server < EM::Connection

      attr_accessor :peer

      def initialize(switchboard)
        @switchboard = switchboard
      end

      def post_init
        puts "Relay::IO::Server#post_init"
        @handler = MessageHandler.new(self)
        @switchboard << Relay::IO::Switchboard::HandshakeCompleted[self]
      end

      def receive_data(data)
        puts "Relay::IO::Server#receive_data #{data.unpack('H*')}"
        return if data.strip.empty?
        @handler.handle(data)
      end

      def send_message(message)
        puts "Relay::IO::Server#send_message #{message.to_payload}"
        send_data(message.to_payload)
      end

      def unbind
        puts "Relay::IO::Server#unbind"
      end
    end
  end
end
# EM.run do
#   EM.start_server(HOST, PORT, Server)
# end
