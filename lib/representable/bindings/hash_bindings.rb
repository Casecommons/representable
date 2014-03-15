require 'representable/binding'

module Representable
  module Hash
    class PropertyBinding < Representable::Binding
      include Binding::Object

      def self.build_for(definition, *args)  # TODO: remove default arg.
        return CollectionBinding.new(definition, *args)  if definition.array?
        return HashBinding.new(definition, *args)        if definition.hash?
        new(definition, *args)
      end

      def read(hash)
        return FragmentNotFound unless hash.has_key?(as) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.

        fragment = hash[as]
        deserialize(fragment)
      end

      def write(hash, value)
        hash[as] = serialize(value)
      end

      def deserialize_from(fragment)
        deserialize(fragment)
      end

      def serialize_method
        :to_hash
      end

      def deserialize_method
        :from_hash
      end
    end

    class CollectionBinding < PropertyBinding
      def serialize(value)
        # value.enum_for(:each_with_index).collect { |obj, i| serialize(obj, i) } # DISCUSS: provide ary index/hash key for representer_module_for?
        value.collect { |item| super(item) } # TODO: i don't want Array but Forms here - what now?
      end

      def deserialize(fragment)
        CollectionDeserializer.new(self).deserialize(fragment)
      end
    end


    class HashBinding < PropertyBinding
      def serialize(value)
        # requires value to respond to #each with two block parameters.
        {}.tap do |hsh|
          value.each { |key, obj| hsh[key] = super(obj) }
        end
      end

      def deserialize(fragment)
        {}.tap do |hsh|
          fragment.each { |key, item_fragment| hsh[key] = super(item_fragment) }
        end
      end
    end
  end
end
