require "representable/deserializer"

module Representable
  class ObjectSerializer < ObjectDeserializer
    def initialize(binding, object)
      super(binding)
      @object = object
    end

    def call
      # return unless @binding.typed? # FIXME: fix that in XML/YAML.
      return @object if @object.nil? # DISCUSS: move to Object#serialize ?

      representable = prepare(@object)

      serialize(representable, @binding.user_options)
    end

  private
    def serialize(object, user_options)
      return object unless @binding.representable?

      name = @binding[:as].evaluate(:value) || (@binding.name)

      options = user_options.merge(:wrap => false, :name => (name unless name.to_s == "_self"))

      object.send(@binding.serialize_method, options)
    end
  end
end
