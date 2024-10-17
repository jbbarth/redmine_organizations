class IssuesOrganization < ActiveRecord::Base

  belongs_to :issue
  belongs_to :organization

end
