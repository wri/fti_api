require 'spec_helper'

RSpec.shared_examples 'jsonapi-resources' do |model_class, options = {}|
  before(:all) do
    @model_class = model_class
    @plural = model_class.model_name.plural
    @singular = model_class.model_name.singular
    @route_key = options[:route_key] || model_class.model_name.route_key
    @collection = model_class.model_name.collection
  end

  before(:each) do
    Rails.cache.clear
  end

  include_examples('jsonapi-resources__show', options[:show]) if options[:show]
  include_examples('jsonapi-resources__create', options[:create]) if options[:create]
  include_examples('jsonapi-resources__edit', options[:edit]) if options[:edit]
  include_examples('jsonapi-resources__delete', options[:delete]) if options[:delete]
  include_examples('jsonapi-resources__pagination', options[:pagination]) if options[:pagination]
  include_examples('jsonapi-resources__sort', options[:sort]) if options[:sort]
  include_examples('jsonapi-resources__filter', options[:filter]) if options[:filter]
end
