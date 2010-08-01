#includes awesome_nested_set 1.4.3 since Redmine's one is far too old
require 'awesome_nested_set2/awesome_nested_set2'
require 'awesome_nested_set2/helper'

ActiveRecord::Base.send(:include, CollectiveIdea::Acts::NestedSet2)
ActionView::Base.send(:include, CollectiveIdea::Acts::NestedSet2::Helper)
