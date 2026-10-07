class OrganizationQuery < Query
  # Core query helpers render a value as a list only when it is an Array
  class UsersColumn < QueryColumn
    def value_object(object)
      super.to_a.sort
    end
  end

  # Boolean columns may be NULL, which means false
  class BooleanColumn < QueryColumn
    def initialize(name, options = {})
      statement = -> { "COALESCE(#{Organization.table_name}.#{name}, #{Organization.connection.quoted_false})" }
      super(name, options.merge(sortable: statement, groupable: true))
    end

    def value_object(object)
      !!super
    end

    def group_by_statement
      sortable
    end
  end

  self.queried_class = Organization
  self.view_permission = :search_project

  self.available_columns = [
    QueryColumn.new(:name, sortable: "#{Organization.table_name}.name"),
    QueryColumn.new(:name_with_parents, sortable: "#{Organization.table_name}.name_with_parents"),
    QueryColumn.new(:identifier, sortable: "#{Organization.table_name}.identifier"),
    QueryColumn.new(:description, sortable: "#{Organization.table_name}.description"),
    QueryColumn.new(:mail, sortable: "#{Organization.table_name}.mail"),
    QueryColumn.new(:parent_fullname,
                    sortable: "(SELECT parents.name_with_parents FROM #{Organization.table_name} parents" \
                              " WHERE parents.id = #{Organization.table_name}.parent_id)",
                    caption: :field_parent_organization),
    BooleanColumn.new(:direction),
    BooleanColumn.new(:top_department_in_ldap),
    UsersColumn.new(:team_leaders),
    UsersColumn.new(:managers),
    QueryColumn.new(:users_count, sortable: "#{Organization.table_name}.users_count"),
    QueryColumn.new(:created_at, sortable: "#{Organization.table_name}.created_at", caption: :field_created_on),
    QueryColumn.new(:updated_at, sortable: "#{Organization.table_name}.updated_at", caption: :field_updated_on)
  ]

  validate do |query|
    query.errors.add(:project_id, :exclusion) if query.project.present?
  end

  def initialize(attributes = nil, *args)
    super(attributes)
    self.filters ||= {}
  end

  def initialize_available_filters
    add_available_filter "name", type: :text, label: :field_name
    add_available_filter "identifier", type: :string
    add_available_filter "description", type: :text
    add_available_filter "mail", type: :string
    add_available_filter "parent_id",
                         type: :list_optional, label: :field_parent_organization,
                         values: -> { Organization.sorted.pluck(:name_with_parents, :id).map { |name, id| [name, id.to_s] } }
    add_available_filter "direction", type: :list, values: yes_no_values
    add_available_filter "top_department_in_ldap", type: :list, values: yes_no_values
    add_available_filter "team_leader_id",
                         type: :list_optional, label: :field_team_leaders,
                         values: -> { users_values(OrganizationTeamLeader) }
    add_available_filter "manager_id",
                         type: :list_optional, label: :field_managers,
                         values: -> { users_values(OrganizationManager) }
    add_available_filter "users_count", type: :integer
    add_available_filter "created_at", type: :date_past, label: :field_created_on
    add_available_filter "updated_at", type: :date_past, label: :field_updated_on
  end

  def default_columns_names
    @default_columns_names ||= [:name, :description, :team_leaders, :managers]
  end

  def default_sort_criteria
    []
  end

  # Results are in tree order unless another sort or grouping is requested
  def tree_order?
    sort_criteria.empty? && group_by.blank?
  end

  def base_scope
    Organization.where(statement)
  end

  def results_scope(options = {})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
    order_option << "#{Organization.table_name}.lft ASC"

    scope = base_scope.
      order(order_option).
      joins(joins_for_order_statement(order_option.join(',')))
    scope = scope.preload(:parent) if has_column?(:parent_fullname)
    scope = scope.preload(:team_leaders) if has_column?(:team_leaders)
    scope = scope.preload(:managers) if has_column?(:managers)
    scope
  end

  def sql_for_name_field(field, operator, value)
    sql_for_field(field, operator, value, Organization.table_name, 'name_with_parents')
  end

  def sql_for_direction_field(field, operator, value)
    sql_for_boolean_field('direction', operator, value)
  end

  def sql_for_top_department_in_ldap_field(field, operator, value)
    sql_for_boolean_field('top_department_in_ldap', operator, value)
  end

  def sql_for_team_leader_id_field(field, operator, value)
    sql_for_organization_user_field(OrganizationTeamLeader, field, operator, value)
  end

  def sql_for_manager_id_field(field, operator, value)
    sql_for_organization_user_field(OrganizationManager, field, operator, value)
  end

  private

  def yes_no_values
    [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]
  end

  def users_values(join_model)
    User.where(id: join_model.select(:user_id)).sorted.map { |user| [user.name, user.id.to_s] }
  end

  def sql_for_boolean_field(db_field, operator, value)
    return '1=1' if value.size > 1

    column = "#{Organization.table_name}.#{db_field}"
    expected = (value.first.to_s == '1') == (operator == '=')
    if expected
      "#{column} = #{self.class.connection.quoted_true}"
    else
      "(#{column} IS NULL OR #{column} = #{self.class.connection.quoted_false})"
    end
  end

  def sql_for_organization_user_field(join_model, field, operator, value)
    exists = operator.start_with?('!') ? 'NOT EXISTS' : 'EXISTS'
    condition =
      if ['*', '!*'].include?(operator)
        ''
      else
        " AND #{sql_for_field(field, '=', value, join_model.table_name, 'user_id')}"
      end
    "#{exists} (SELECT 1 FROM #{join_model.table_name}" \
      " WHERE #{join_model.table_name}.organization_id = #{Organization.table_name}.id#{condition})"
  end
end
