require 'redmine/field_format'

module Redmine
  module FieldFormat

    class OrganizationFormat < RecordList
      add 'organization'

      def possible_values_options(custom_field, object = nil)
        organizations = possible_values_records(custom_field, object)
        options = organizations.map { |u| [u.fullname, u.id.to_s] }
        options
      end

      def possible_values_records(custom_field, object = nil)
        Organization.sorted
      end

    end

  end
end
