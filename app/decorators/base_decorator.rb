# frozen_string_literal: true

class BaseDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers

  attr_reader :model

  def self.decorate_collection(collection, view_context = nil)
    collection.map { |item| new(item, view_context) }
  end

  def self.decorate(model, view_context = nil)
    new(model, view_context)
  end

  def initialize(model, view_context = nil)
    super(model)
    @model = model
    @view_context = view_context
  end

  def h
    @view_context
  end
end
