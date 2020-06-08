require 'spec_helper'

RSpec.shared_examples 'forest_typeable' do |model_class|
  it { is_expected.to define_enum_for(:forest_type).with_values(
    model_class::FOREST_TYPES.map {|x| {x.first => x.last[:index]}}.reduce({}, :merge)
  ) }
end
