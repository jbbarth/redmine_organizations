class OrganizationRole < ActiveRecord::Base
  belongs_to :organization_membership
  belongs_to :role
end
