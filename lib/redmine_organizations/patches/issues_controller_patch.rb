require_dependency 'issues_controller'

module RedmineOrganizations::Patches
  module IssuesControllerPatch

    def set_organizations
      return unless User.current.allowed_to?(:share_issues_with_organizations, @issue.project)

      if params[:issue] && params[:issue][:organization_ids]
        organizations = Organization.where(id: params[:issue][:organization_ids])
        update_journal_with_organizations(old_value: @issue.organizations,
                                          new_value: organizations) if @issue.persisted?
        @issue.organizations = organizations
      end
    end

    def update_journal_with_organizations(old_value:, new_value:)
      @current_journal = @issue.init_journal(User.current)
      # organizations removed
      removed_values = old_value - new_value
      @current_journal.details << JournalDetail.new(:property => 'attr', :prop_key => 'issue_organizations',
                                                    :old_value => removed_values.reject(&:blank?).join(","),
                                                    :value => nil) if removed_values.present?
      # organizations added
      added_values = new_value - old_value
      @current_journal.details << JournalDetail.new(:property => 'attr', :prop_key => 'issue_organizations',
                                                    :old_value => nil,
                                                    :value => added_values.reject(&:blank?).join(",")) if added_values.present?
    end
  end
end

class IssuesController

  prepend RedmineOrganizations::Patches::IssuesControllerPatch

  append_before_action :set_organizations, :only => [:create, :update]

end