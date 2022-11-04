# frozen_string_literal: true

require 'paranoia'
require 'globalize'

Globalize::ActiveRecord::ActMacro.module_eval do
  def setup_translates_with_paranoia!(options)
    setup_translates_without_paranoia!(options)

    if options[:paranoia] && translation_class.attribute_names.include?('deleted_at')
      translation_class.send(:acts_as_paranoid, without_default_scope: true)
    end
  rescue ::ActiveRecord::NoDatabaseError
    warn 'Unable to connect to a database. Setup translates with paranoia'
  end

  alias_method :setup_translates_without_paranoia!, :setup_translates!
  alias_method :setup_translates!, :setup_translates_with_paranoia!
end
