class Organization < ActiveRecord::Base
  unloadable
  acts_as_nested_set2

  # Reorder tree after save on the fly
  # Less beautiful than Redmine method to keep tree sorted,
  # But also far less complicated
  after_save do |org|
    siblings = org.siblings
    while org.left_sibling && org.left_sibling < org
      org.move_left
    end
  end
  
  def <=>(other)
    other.name.casecmp(self.name)
  end
  
  def name
    read_attribute(:name) || ""
  end
end
