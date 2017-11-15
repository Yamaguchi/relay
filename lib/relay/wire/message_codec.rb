module Relay
  module Wire
    module MessageCodec
      Message = Algebrick.type do
        variants Ping = atom,
        Pong = atom,
        NewConnection = type { fields! remote_node_id: String, address: String, new_channel_opt: Hash }
      end
      Algebrick.type do
        variants Event = type { fields! message_type: Message, data: Object, conn: Object },
        HandshakeCompleted = type { fields! conn: EM::Connection },
        Timeout = type { fields! conn: EM::Connection }
      end
    end
  end
end
