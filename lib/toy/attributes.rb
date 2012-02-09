module Toy
  module Attributes
    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      attribute_method_suffix('', '=', '?')
    end

    module ClassMethods
      def attributes
        @attributes ||= {}
      end

      def defaulted_attributes
        attributes.values.select(&:default?)
      end

      def attribute(key, type, options = {})
        define_attribute_methods([key]) unless (key == :id) 
        Attribute.new(self, key, type, options)        
      end

      def attribute?(key)
        attributes.has_key?(key.to_s)
      end
      
      def define_attribute_methods(name)
        super(name)
      end
    end

    def initialize(attrs={})
      # debugger
      @_new_record = true unless defined?(@_new_record)
      initialize_attributes_with_defaults
      send(:attributes=, attrs, @_new_record)
      write_attribute :id, self.class.next_key(self) unless id?
    end
    
    def initialize_from_database(attrs={})
      @_new_record = false
      send(:initialize, attrs)
      self
    end
    
    def reload
      if attrs = store.read(id)
        attrs['id'] = id
        instance_variables.each        { |ivar| instance_variable_set(ivar, nil) }
        initialize_attributes_with_defaults
        send(:attributes=, attrs, new_record?)
        self.class.lists.each_key      { |name| send(name).reset }
        self.class.references.each_key { |name| send(name).reset }
      else
        raise NotFound.new(id)
      end
      self
    end
    
    def id
      read_attribute(:id)
    end
    
    def attributes
      @attributes
    end
    
    def persisted_attributes
      {}.tap do |attrs|
        self.class.attributes.each do |name, attribute|
          next if attribute.virtual?
          attrs[attribute.persisted_name] = attribute.to_store(read_attribute(attribute.name))
        end
      end.merge(embedded_attributes)
    end
    
    def embedded_attributes
      {}.tap do |attrs|
        self.class.embedded_lists.each_key do |name|
          attrs[name.to_s] = send(name).map(&:persisted_attributes)
        end
      end
    end
    
    def attributes=(attrs, *)
      return if attrs.nil?
      attrs.each do |key, value|
        if attribute_method?(key)
          write_attribute(key, value)
        elsif respond_to?("#{key}=")
          send("#{key}=", value)
        end
      end
    end
    
    def [](key)
      read_attribute(key)
    end
    
    def []=(key, value)
      write_attribute(key, value)
    end
    
    private
      def read_attribute(key)
        @attributes ||= {}
        @attributes[key.to_s]
      end
    
      def write_attribute(key, value)
        @attributes[key.to_s] = attribute_definition(key).try(:from_store, value)
      end
    
      def attribute_definition(key)
        self.class.attributes[key.to_s]
      end
    
      def attribute_method?(key)
        self.class.attribute?(key)
      end
    
      def attribute(key)
        read_attribute(key)
      end
    
      def attribute=(key, value)
        write_attribute(key, value)
      end
    
      def attribute?(key)
        read_attribute(key).present?
      end
    
      def initialize_attributes_with_defaults
        @attributes ||= {}
        self.class.defaulted_attributes.each do |attribute|
          @attributes[attribute.name.to_s] = attribute.default
        end
      end
      
      # def method_missing(method, *args, &block)
      #   self.class.define_attribute_methods
      #   super
      # end
  end
end