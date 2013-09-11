require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'

# This ugly patch is only useful in db:migrate/redmine:plugin:migrate
# when the database is not fully ready. Then when Redmine loads this
# plugin it tries to load project, principal, then group models, but
# one scope defined in the original model breaks because it uses the
# the "users" table directly, which may not exist at this point.
#
# So basically loading Group scoped at this point is not possible, so
# we mock the "order" method in order to neutralize this behaviour (we
# don't need "order" in migrations...).
#
# This is *not* fun. Will try to propose a patch..
if File.basename($0) == "rake" && ARGV.first.match(/^db:|^redmine:/)
  class Group < Principal
    def self.order(*args)
      if table_exists?
        super
      else
        #we don't care, we're in a db:migrate or so..
        lambda{}
      end
    end
  end
end

require_dependency 'group'

class Group
  _callback = _validate_callbacks.find { |c|
    c.raw_filter.is_a?(ActiveModel::Validations::LengthValidator) &&
    c.raw_filter.instance_variable_get(:@attributes).try(:include?, :lastname)
  }
  skip_callback(:validate, _callback.kind, _callback.filter)
end
