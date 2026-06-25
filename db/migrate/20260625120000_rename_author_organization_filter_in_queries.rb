class RenameAuthorOrganizationFilterInQueries < ActiveRecord::Migration[7.2]
  # The "author organization" issue filter was renamed from "author_organization"
  # to "author.organization" so it is grouped under the "Author" section.
  # Rewrite the filter key stored in existing saved queries so they keep working.
  # Only the filter is renamed, not the column.

  def up
    rename_filter_key('author_organization', 'author.organization')
  end

  def down
    rename_filter_key('author.organization', 'author_organization')
  end

  private

  def rename_filter_key(from, to)
    Query.where("filters LIKE ?", "%#{from}%").find_each do |query|
      filters = query.filters
      next unless filters.is_a?(Hash) && filters.key?(from)

      query.filters = filters.transform_keys { |key| key == from ? to : key }
      query.save(validate: false)
    end
  end
end
