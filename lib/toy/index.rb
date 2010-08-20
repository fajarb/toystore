module Toy
  class Index
    attr_accessor :model, :name

    def initialize(model, name)
      @model, @name = model, name.to_sym
      raise(ArgumentError, "No attribute #{name} for index") unless model.attribute?(name)

      model.indices[name] = self
      model.send(:include, IndexCallbacks)
    end

    def eql?(other)
      self.class.eql?(other.class) &&
        model == other.model &&
        name  == other.name
    end
    alias :== :eql?

    def key(value)
      [model.name, name, value].join(':')
    end

    module IndexCallbacks
      extend ActiveSupport::Concern

      included do
        after_create  :index_create
        after_update  :index_update
        after_destroy :index_destroy
      end

      def index_create
        indices.each_key do |name|
          create_index(name, send(name), id)
        end
      end

      def index_update
        indices.each_key do |name|
          if send(:"#{name}_changed?")
            destroy_index(name, send(:"#{name}_was"), id)
            create_index(name, send(name), id)
          end
        end
      end

      def index_destroy
        indices.each_key do |name|
          destroy_index(name, send(name), id)
        end
      end
    end
  end
end