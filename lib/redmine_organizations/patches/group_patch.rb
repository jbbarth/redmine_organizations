require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'
require_dependency 'group'

class Group
  _callback = _validate_callbacks.find { |c|
    c.raw_filter.is_a?(ActiveModel::Validations::LengthValidator) &&
    c.raw_filter.instance_variable_get(:@attributes).try(:include?, :lastname)
  }
  skip_callback(:validate, _callback.kind, _callback.filter)
end
