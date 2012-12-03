require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'

# It is not possible to "require 'group'" now because at this point,
# it's possible we don't even have a proper DB. In this case, loading
# Group scopes is not possible, since ":order" scope is defined without
# a lambda, so AR tries to find the "users" table layout and fails.
#
# So we have to override/fake it and make like we're smarter.
#
# Not fun. Will try to propose a patch..
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

require_dependency 'group'

class Group
  _callback = _validate_callbacks.find { |c|
    c.raw_filter.is_a?(ActiveModel::Validations::LengthValidator) &&
    c.raw_filter.instance_variable_get(:@attributes).try(:include?, :lastname)
  }
  skip_callback(:validate, _callback.kind, _callback.filter)
end
