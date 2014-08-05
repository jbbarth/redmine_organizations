class Organization < ActiveRecord::Base
  unloadable
  acts_as_nested_set

  validates_presence_of :name
  validates :name, :uniqueness => {:scope => :parent_id}
  validates_format_of :mail, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :allow_blank => true

  has_many :users
  has_many :memberships, :class_name => 'OrganizationMembership', :dependent => :delete_all
                        #:include => [:project], :conditions => "#{Project.table_name}.status<>#{Project::STATUS_ARCHIVED}"
  has_many :projects, :through => :memberships
  
  SEPARATOR = '/'

  # Reorder tree after save on the fly
  # Less beautiful than Redmine method to keep tree sorted,
  # But also far less complicated
  after_save do |org|
    siblings = org.siblings
    while org.left_sibling && org.left_sibling.name > org.name
      org.move_left
    end
  end
  
  def <=>(other)
    other.name.casecmp(self.name)
  end
  
  def name
    read_attribute(:name) || ""
  end
  
  def fullname
    @fullname ||= ancestors.all(:order => 'lft').map do |ancestor|
      ancestor.name+Organization::SEPARATOR
    end.join("") + name
  end

  def direction_organization
    @direction_organization ||= (direction? || root? ? self : parent.direction_organization)
  end

  # Yields the given block for each organization with its level in the tree
  def self.organization_tree(organizations, &block)
    ancestors = []
    organizations.sort_by(&:lft).each do |organization|
      while (ancestors.any? && !organization.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield organization, ancestors.size
      ancestors << organization
    end
  end
end
