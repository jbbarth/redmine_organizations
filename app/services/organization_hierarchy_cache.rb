class OrganizationHierarchyCache
  def initialize(organizations)
    @organizations = organizations.to_a
    preload_ancestors!
  end

  def self_and_ancestors(org)
    ancestors = []
    current = org
    while current
      ancestors.unshift(current)
      current = @all_organizations_by_id[current.parent_id]
    end
    ancestors
  end

  def top_department_in_ldap(org)
    self_and_ancestors(org).find(&:top_department_in_ldap?)
  end

  def fullpath_from_top_department(org)
    top = top_department_in_ldap(org)
    org.name_to_(top)
  end

  private

  def preload_ancestors!
    all_ids = @organizations.map(&:id) + @organizations.map(&:parent_id).compact
    loop do
      new_parents = Organization.where(id: all_ids.uniq).pluck(:parent_id).compact
      break if (new_parents - all_ids).empty?

      all_ids |= new_parents
    end

    @all_organizations_by_id = Organization.where(id: all_ids).index_by(&:id)
  end
end
