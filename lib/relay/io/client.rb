# frozen_string_literal: true

module Relay
  module IO
    class Client < Concurrent::Actor::RestartingContext
      include Algebrick::Matching
      include Relay::Wire::MessageCodec

      module Status
        HANDSHAKE = 1
        CONNECTED = 2
      end

      attr_accessor :conn, :host, :port

      def initialize(switchboard, remote_node_id, host, port)
        @switchboard = switchboard
        @remote_node_id = remote_node_id
        @host = host
        @port = port
        @status = Status::HANDSHAKE
        @listeners = []
      end

      def self.connect(host, port, switchboard, remote_node_id)
        client = spawn(:client, switchboard, remote_node_id, host, port)
        EM.connect(host, port, ClientConnection, client, host, port)
      end

      def on_message(message)
        log(Logger::DEBUG, "status:#{@status}:#{message}")
        case @status
        when Status::HANDSHAKE
          match message, (on HandshakeCompleted.(remote_node_id: any, conn: any, host: any, port: any) do |_, _, _, _|
            @switchboard << HandshakeCompleted[@remote_node_id, self, @host, @port]
            @status = Status::CONNECTED
          end), (on any)
        when Status::CONNECTED
          match message, (on Received.(~any, ~any, any, any) do |remote_node_id, m|
            @listeners.each { |listener| listener << Event[m, remote_node_id, self] }
          end), (on Message.(~any) do |m|
            @conn.send_message(Relay.local_node_id, m)
          end), (on AddListener.(~any) do |listener|
            @listeners << listener
          end), (on any)
        end

        match message, (on Set.(~any) do |conn|
          @conn = conn
          return
        end), (on any)
      end
      class ClientConnection < EM::Connection
        include Relay::Wire::MessageCodec
        include Concurrent::Concern::Logging

        def initialize(client, host, port)
          @client = client
          @client << Set[self]
          @host = host
          @port = port
        end

        def post_init
          log(Logger::DEBUG, @client.path, 'Relay::IO::ClientConnection#post_init')
          @handler = MessageHandler.new(@client, @host, @port)
        end

        def connection_completed
          log(Logger::DEBUG, @client.path, 'Relay::IO::ClientConnection#connection_completed')
          @client << HandshakeCompleted['', @client, @host, @port]
        end

        def receive_data(data)
          log(Logger::DEBUG, @client.path, "Relay::IO::ClientConnection#receive_data #{data.bth}")
          return if data.strip.empty?
          @handler.handle(data)
        end

        def unbind(reason = nil)
          log(Logger::DEBUG, @client.path, "Relay::IO::ClientConnection#unbind #{reason}")
        end

        def send_message(local_node_id, message)
          log(Logger::DEBUG, @client.path, "Relay::IO::ClientConnection#send_message #{message}")
          send_data(local_node_id.htb + message.to_payload)
        end
      end
    end
  end
end
