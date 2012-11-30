require 'test/unit'
require 'active_support/test_case'
require 'rspec'

# IMPORTANT DISCLAIMER ABOUT THIS HACK
#
# I am *not* proud of this one, but at least it doesn't break
# other plugins and redmine tests. Redmine's whole test suite
# is built around test/unit and shoulda, which is not something
# I like, but it's like that. If I just put my spec next to
# test/unit ones and require rspec/autorun, it just breaks a
# lot of shoulda keywords, hence break most of my plugins
# tests, so here we are...
#
# Please tell me if you have a better idea, I'd gladly offer a
# beer or two.
class RedmineOrganizationsSpecs < ActiveSupport::TestCase
  def test_specs
    assert_equal 0, RSpec::Core::Runner::run([File.expand_path('../../../spec', __FILE__)], $stderr, $stdout)
  end
end

