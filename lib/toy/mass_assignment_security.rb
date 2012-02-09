module Toy
  module MassAssignmentSecurity
    extend ActiveSupport::Concern
    include ActiveModel::MassAssignmentSecurity

    def attributes=(attrs, guard_protected_attributes=true)
      attrs = sanitize_for_mass_assignment(attrs || {}) if guard_protected_attributes
      super(attrs)
    end
  end
end