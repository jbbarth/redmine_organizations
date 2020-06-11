require 'redmine/field_format'

module Redmine
  module FieldFormat

    class OrganizationFormat < RecordList
      add 'organization'
      self.form_partial = 'custom_fields/formats/organization'
      field_attributes :direction_only

      def possible_values_options(custom_field, object = nil)
        organizations = possible_values_records(custom_field, object)
        options = organizations.map { |u| [u.fullname, u.id.to_s] }
        options
      end

      def possible_values_records(custom_field, object = nil)
        if custom_field.direction_only == '1'
          Organization.direction.sorted
        else
          Organization.sorted
        end
      end

    end

  end
end

class CustomField < ActiveRecord::Base
  safe_attributes('direction_only')
end
