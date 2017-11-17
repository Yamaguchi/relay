# frozen_string_literal: true

module Relay
  module IO
    class Server < Concurrent::Actor::RestartingContext
      include Algebrick::Matching
      include Relay::Wire::MessageCodec

      module Status
        HANDSHAKE = 1
        LISTEN = 2
      end

      attr_accessor :conn

      def initialize(switchboard)
        @switchboard = switchboard
        @status = Status::HANDSHAKE
        @listeners = []
      end

      def self.start_server(host, port, switchboard)
        server = spawn(:server, switchboard)
        puts "start_server"
        EM.start_server(host, port, ServerConnection, server)
      end

      def on_message(message)
        log(Logger::DEBUG, "status:#{@status}:#{message}")
        case @status
        when Status::HANDSHAKE
          match message, (on Received.(~any, any, ~any, ~any) do |remote_node_id, host, port|
            @switchboard << HandshakeCompleted[remote_node_id, self, host, port]
            # @listeners.each { |listener| listener << Event[m, remote_node_id, self] }
            # reference << received
            @status = Status::LISTEN
          end), (on any)
        when Status::LISTEN
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

      class ServerConnection < EM::Connection
        include Relay::Wire::MessageCodec
        include Concurrent::Concern::Logging

        def initialize(server)
          @server = server
          @server << Set[self]
        end

        def post_init
          log(Logger::DEBUG, @server.path, 'Relay::IO::ServerConnection#post_init')
          _, ip = Socket.unpack_sockaddr_in(get_peername)
          @handler = MessageHandler.new(@server, ip, 0)
        end

        def receive_data(data)
          log(Logger::DEBUG, @server.path, "Relay::IO::ServerConnection#receive_data #{data.bth}")
          return if data.strip.empty?
          @handler.handle(data)
        end

        def unbind(reason = nil)
          log(Logger::DEBUG, @server.path, "Relay::IO::ServerConnection#unbind #{reason}")
        end

        def send_message(local_node_id, message)
          log(Logger::DEBUG, @server.path, "Relay::IO::ServerConnection#send_message #{message}")
          send_data(local_node_id.htb + message.to_payload)
        end
      end
    end
  end
end
