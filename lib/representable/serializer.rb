require "representable/deserializer"

module Representable
  class ObjectSerializer < ObjectDeserializer
    def call # TODO: make typed? switch here!
      return @object if @object.nil?
      representable = prepare(@object)
      return representable unless @binding.typed?

      options = @binding.user_options.merge(as: @binding.options[:as], wrap: false)

      representable.send(@binding.serialize_method, options)
    end
  end
end
