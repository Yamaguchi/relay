module Relay
  module Wire
    module MessageCodec
      Algebrick.type do
        variants Ping = atom,
            Pong = atom
      end
    end
  end
 end
