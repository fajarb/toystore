module Toy
  module Logger
    extend ActiveSupport::Concern

    module ClassMethods
      OperationsToLogValueFor = [:get, :set, :del]

      def logger
        Toy.logger
      end

      def log_operation(operation, model, adapter, key, value=nil)
        if logger && logger.debug?
          logger.debug("TOYSTORE #{operation.to_s.upcase} #{model} :#{adapter.name} #{key.inspect}")
          logger.debug("  #{value.inspect}") if !value.nil? && OperationsToLogValueFor.include?(operation)
        end
      end
    end

    def logger
      Toy.logger
    end
    
    def log_operation(*args)
      self.class.log_operation(*args)
    end
  end
end