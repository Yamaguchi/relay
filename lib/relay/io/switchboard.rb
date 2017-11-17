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
        @peers = ::Relay::DB::Peer.all.inject({}) do |peers, peer|
          peers.merge!("#{peer.remote_node_id}": ::Relay::IO::Peer.spawn('peer', host: peer.host))
        end
        @connections = {}
      end

      def on_message(message)
        log(Logger::DEBUG, "Switchboard#on_message #{message}")
        match message, (on ~NewConnection.(node_id: String, host: '0.0.0.0', new_channel_opt: any) do
          raise 'can not connect local address.'
        end), (on ~NewConnection do |remote_node_id, host, _|
          unless @connections[remote_node_id]
            @connections[remote_node_id] = connect(host, 9735, remote_node_id)
          end
        end), (on HandshakeCompleted.(remote_node_id: ~any, conn: ~any, host: ~any, port: ~any) do |remote_node_id, conn, host, port|
          unless @peers[remote_node_id]
            @peers[remote_node_id] = ::Relay::IO::Peer.spawn('peer', remote_node_id: remote_node_id, host: host)
            ::Relay::DB::Peer.create(remote_node_id: remote_node_id, host: host)
          end
          @peers[remote_node_id] << HandshakeCompleted[remote_node_id, conn, host, port]
          conn << AddListener[@peers[remote_node_id]]
        end), (on any do
          log(Logger::WARN, 'NO OP')
        end)
      end

      def connect(host, port, remote_node_id)
        ::Relay::IO::Client.connect(host, port, reference, remote_node_id)
      end
    end
  end
end
