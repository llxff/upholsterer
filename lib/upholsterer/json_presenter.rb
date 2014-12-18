require 'active_support/core_ext/module/delegation'

module Upholsterer
  class Base
    delegate :to_json, :as_json, to: :to_hash, prefix: false

    def to_hash
      Hash[json_fields.collect do |field|
        [field, public_send(field)]
      end]
    end

    alias :to_h :to_hash

  private

    def json_fields
      @json_fields ||= public_methods(false).tap do |fields|
        fields.delete(:subject)
        fields.delete(:respond_to?)
        fields.delete(:method_missing)
      end
    end
  end
end