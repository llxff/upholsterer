module Upholsterer
  class Base
    def to_hash
      Hash[json_fields.collect do |field|
        [field, public_send(field)]
      end]
    end

    def to_json(*args)
      to_hash.to_json(*args)
    end

    alias :to_h :to_hash
    alias :as_json :to_json

    private
    def json_fields
      @json_fields ||= public_methods(false).tap do |fields|
        fields.delete(:subject)
      end
    end
  end
end