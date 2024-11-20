class IssuesOrganization < ApplicationRecord

  belongs_to :issue
  belongs_to :organization

end
