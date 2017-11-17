# frozen_string_literal: true

require 'json'

module Relay
  module DB
    class Peer
      attr_accessor :remote_node_id, :host

      def initialize(remote_node_id: nil, host: nil)
        @remote_node_id = remote_node_id
        @host = host
      end

      def self.db
        @db ||= ::LevelDB::DB.new '/tmp/peers'
      end

      def self.create(remote_node_id: nil, host: nil)
        db.put(remote_node_id, { remote_node_id: remote_node_id, host: host }.to_json)
        new(remote_node_id: remote_node_id, host: host)
      end

      def destroy
        Peer.db.delete(remote_node_id)
        self
      end

      def self.all
        db.map { |_, v| new(JSON.parse(v, symbolize_names: true)) }
      end
    end
  end
end
