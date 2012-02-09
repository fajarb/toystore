module Toy
  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    included do
      extend ActiveModel::Callbacks
      define_model_callbacks :validation
    end

    module ClassMethods
      def validates_embedded(*names)
        validates_each(*names) do |record, name, value|
          invalid = value.compact.select { |obj| !obj.valid? }
          if invalid.any?
            record.errors.add(name, 'is invalid')

            if logger && logger.debug?
              invalid_messages = []
              invalid.each do |obj|
                invalid_messages << [obj.attributes, obj.errors.full_messages]
              end
              log_operation(:iem, self.name, store, record.id, invalid_messages)
            end
          end
        end
      end

      def create!(attrs={})
        new(attrs).tap { |doc| doc.save! }
      end
    end

    def valid?
      run_callbacks(:validation) { super }
    end
    
    def save(options={})
      options.assert_valid_keys(:validate)
      !options.fetch(:validate, true) || valid? ? super : false
    end
    
    def save!
      save || raise(RecordInvalid.new(self))
    end
  end
end