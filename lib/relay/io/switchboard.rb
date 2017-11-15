# frozen_string_literal: true

require 'singleton'
module Relay
  module IO
    # Ties network connections to peers.
    class Switchboard < Concurrent::Actor::RestartingContext
      include Algebrick::Matching
      include Relay::Wire::MessageCodec

      module Status
        DISCONNECTED = 1
        INITIALIZING = 2
        CONNECTED = 3
      end

      attr_reader :peers, :connections

      def initialize
        @peers = {}
        @connections = {}
      end

      def on_message(message)
        log(Logger::DEBUG, "Switchboard#on_message #{message}")
        match message, (on ~NewConnection.call(remote_node_id: String, address: '0.0.0.0', new_channel_opt: any) do
          raise 'can not connect local address.'
        end), (on ~NewConnection.call(remote_node_id: String, address: String, new_channel_opt: any) do |remote_node_id, address, _|
          connection = connect(address, 9735)
          @connections[remote_node_id] = connection

          # peer = ::Relay::IO::Peer.new
          # @peers[remote_node_id] = peer
        end), (on HandshakeCompleted.(~any) do |conn|
          # peer = ::Relay::IO::Peer.new(connection)
          # @peers[remote_node_id] = peer
          peer = ::Relay::IO::Peer.spawn('peer')
          peer << HandshakeCompleted[conn]
        end), (on Object do
          log(Logger::WARN, "NO OP")
        end)
      end

      def connect(host, port)
        EM.connect(host, port, ::Relay::IO::Client, reference)
      end
    end
  end
end
