require 'active_support/core_ext/module/delegation'

module Upholsterer
  class Base
    delegate :to_json, :as_json, to: :to_hash, prefix: false

    def self.serializable(*args)
      args.each do |method_name|
        attributes[method_name.to_sym] = [method_name.to_sym, { serializable: true }]
      end
    end

    def self.serialize_attributes
      @_json_fields ||= begin
        methods = instance_methods(false).tap do |fields|
          fields.delete(:subject)
          fields.delete(:respond_to?)
          fields.delete(:method_missing)
        end
        (methods + attributes.keys).uniq
      end
    end

    def to_hash
      json = {}

      self.class.serialize_attributes.each do |field|
        json[field] = public_send(field)
      end

      json
    end

    alias :to_h :to_hash
  end
end
