# frozen_string_literal: true

require 'relay/version'

require 'securerandom'

require 'algebrick'
require 'algebrick/serializer'
require 'concurrent'
require 'concurrent-edge'
require 'eventmachine'
require 'leveldb'

module Relay
  module DB
    autoload :Peer, 'relay/db/peer'
  end

  module IO
    autoload :Client, 'relay/io/client'
    autoload :MessageHandler, 'relay/io/message_handler'
    autoload :Peer, 'relay/io/peer'
    autoload :Server, 'relay/io/server'
    autoload :Switchboard, 'relay/io/switchboard'
  end

  autoload :String, 'relay/utils/string'

  module Wire
    autoload :MessageCodec, 'relay/wire/message_codec'
    autoload :MessageTypes, 'relay/wire/message_types'
    autoload :Ping, 'relay/wire/ping'
    autoload :Pong, 'relay/wire/pong'
  end

  @local_node_id = if File.exists?('seed.dat')
    id = File.read('seed.dat')
  else
    id = SecureRandom.hex(32)
    File.write('seed.dat', id)
    id
  end

  def self.local_node_id
    @local_node_id
  end
end

Concurrent.use_simple_logger Logger::DEBUG

Thread.start do
  EM.run do
    switchboard = Relay::IO::Switchboard.spawn(:switchboard)
    Relay::IO::Server.start_server('0.0.0.0', 9735, switchboard)
  end
end
