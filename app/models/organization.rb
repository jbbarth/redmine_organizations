class Organization < ActiveRecord::Base
  unloadable
  acts_as_nested_set
end
