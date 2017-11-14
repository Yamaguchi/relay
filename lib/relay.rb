# frozen_string_literal: true

require 'relay/version'
require 'concurrent'
require 'concurrent-edge'
require 'eventmachine'
require 'algebrick'
require 'algebrick/serializer'
require 'pry'

module Relay
  module IO
    autoload :Client, 'relay/io/client'
    autoload :MessageHandler, 'relay/io/message_handler'
    autoload :Peer, 'relay/io/peer'
    autoload :Server, 'relay/io/server'
    autoload :Switchboard, 'relay/io/switchboard'
  end

  module Wire
    autoload :MessageCodec, 'relay/wire/message_codec'
    autoload :MessageTypes, 'relay/wire/message_types'
    autoload :Ping, 'relay/wire/ping'
    autoload :Pong, 'relay/wire/pong'
  end
end

Thread.start do
  EM.run do
    switchboard = Relay::IO::Switchboard.spawn(:switchboard)
    EM.start_server('0.0.0.0', 9735, Relay::IO::Server, switchboard)
  end
end