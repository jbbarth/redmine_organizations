class OrganizationInvolvement < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization_membership
end
