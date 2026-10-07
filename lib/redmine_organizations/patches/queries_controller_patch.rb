require_dependency 'queries_controller'

module RedmineOrganizations::Patches
  module QueriesControllerPatch
    private

    def redirect_to_organization_query(options)
      redirect_to organizations_path(options)
    end
  end
end

QueriesController.prepend RedmineOrganizations::Patches::QueriesControllerPatch
