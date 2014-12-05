module Upholsterer
  class Base
    def to_hash
      Hash[public_methods(false).collect do |field|
        [field, public_send(field)]
      end]
    end

    def to_json(*args)
      to_hash.to_json(*args)
    end

    alias :to_h :to_hash
    alias :as_json :to_json
  end
end