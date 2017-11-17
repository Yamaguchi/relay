# frozen_string_literal: true

module Relay
  module Wire
    module MessageCodec
      Message = Algebrick.type do
        fields Object
        variants  Ping = type { fields Object },
                  Pong = type { fields Object },
                  NewConnection = type { fields! node_id: String, host: String, new_channel_opt: Hash },
                  Restore = atom
      end
      Algebrick.type do
        variants  Event = type { fields! message_type: Message, remote_node_id: String, conn: Object },
                  HandshakeCompleted = type { fields! remote_node_id: String, conn: Object, host: String, port: Numeric },
                  Received = type { fields! node_id: String, message: Message, host: String, port: Numeric },
                  Timeout = type { fields! conn: Object },
                  AddListener = type { fields! listener: Object },
                  Set = type { fields! data: Object }
      end
    end
  end
end
