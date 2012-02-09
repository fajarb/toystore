module Toy
  module Persistence
    extend ActiveSupport::Concern

    module ClassMethods
      def store(name=nil, client=nil, options={})
        assert_client(name, client)
        @store = Adapter[name].new(client, options) if !name.nil? && !client.nil?
        assert_store(name, client)
        @store
      end

      def has_store?
        !@store.nil?
      end

      def create(attrs={})
        new(attrs).tap { |doc| doc.save }
      end

      def delete(*ids)
        ids.each { |id| get(id).try(:delete) }
      end

      def destroy(*ids)
        ids.each { |id| get(id).try(:destroy) }
      end

      private
        def assert_client(name, client)
          raise(ArgumentError, 'Client is required') if !name.nil? && client.nil?
        end

        def assert_store(name, client)
          raise(StandardError, "No store has been set") if name.nil? && client.nil? && !has_store?
        end
    end

    def store
      self.class.store
    end
    
    def new_record?
      @_new_record == true
    end
    
    def destroyed?
      @_destroyed == true
    end
    
    def persisted?
      !new_record? && !destroyed?
    end
    
    def save(*)
      new_record? ? create : update
    end
    
    def update_attributes(attrs)
      self.attributes = attrs
      save
    end
    
    def destroy
      delete
    end
    
    def delete
      @_destroyed = true
      log_operation(:del, self.class.name, store, id)
      store.delete(id)
    end
    
    private
      def create
        persist!
      end
    
      def update
        persist!
      end
    
      def persist
        @_new_record = false
      end
    
      def persist!
        attrs = persisted_attributes
        attrs.delete('id') # no need to persist id as that is key
        store.write(id, attrs)
        log_operation(:set, self.class.name, store, id, attrs)
        persist
        each_embedded_object { |doc| doc.send(:persist) }
        true
      end
  end
end