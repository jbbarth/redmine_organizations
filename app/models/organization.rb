class Organization < ActiveRecord::Base
  unloadable
  acts_as_nested_set
  
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
    ancestors.all(:order => 'lft').map do |ancestor|
      ancestor.name+Organization::SEPARATOR
    end.join("") + name
  end

  def direction_organization
    @direction_organization ||= (direction? || root? ? self : parent.direction_organization)
  end
end
