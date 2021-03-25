# frozen_string_literal: true

module OpDoc
  class FetchFilterTree
    include Interactor

    def call
      tree
    end

    private

    TYPES = [
      { id: 'OperatorDocumentCountry', name: I18n.t('operator_documents.filters.producer') },
      { id: 'OperatorDocumentFmu', name: I18n.t('operator_documents.filters.fmu') }
    ].freeze

    STATUSES = [
        { id: 'doc_not_provided', name: I18n.t('operator_documents.filters.doc_not_provided') },
        { id: 'doc_valid', name: I18n.t('operator_documents.filters.doc_valid') },
        { id: 'doc_expired', name: I18n.t('operator_documents.filters.doc_expired') },
        { id: 'doc_not_required', name: I18n.t('operator_documents.filters.doc_not_required') }
    ].freeze

    SOURCES = [
        { id: 1, name: I18n.t('filters.company') },
        { id: 2, name: I18n.t('filters.forest_atlas') },
        { id: 3, name: I18n.t('filters.other') }
    ].freeze

    def tree
      context.tree = {
          forest_types: forest_types,
          status: STATUSES,
          country_ids: country_ids,
          operator_id: operator_ids,
          fmu_id: fmu_ids,
          required_operator_document_id: required_operator_document_ids,
          source: SOURCES,
          legal_categories: legal_categories
      }
    end

    def legal_categories
      group_id_to_exclude = RequiredOperatorDocumentGroup.with_translations('en').where(name: "Publication Authorization").first.id
      RequiredOperatorDocumentGroup.with_translations.map do |x|
        unless x.id == group_id_to_exclude
          { id: x.id, name: x.name,
          required_operator_document_ids: x.required_operator_documents.pluck(:id)
         }
        end
      end.compact.sort_by { |x| x[:name] }
    end

    def forest_types
      ConstForestTypes::FOREST_TYPES.map do |key, value| 
        { key: key, id: value[:index], name: value[:label] }
      end.sort_by { |x| x[:name] }
    end

    def fmu_ids
      fmu_id = Fmu.arel_table[:id]
      fmu_name = Arel::Table.new(:fmu_translations)[:name]
      Fmu.all.with_translations.order(:name).pluck(fmu_id, fmu_name).map{ |x| { id: x[0], name: x[1] } }
    end

    def required_operator_document_ids
      group_id_to_exclude = RequiredOperatorDocumentGroup.with_translations('en').where(name: "Publication Authorization").first.id
      RequiredOperatorDocument.with_translations.map do |x|
        unless x.required_operator_document_group_id == group_id_to_exclude
          { id: x.id, name: beautify_name(x.name) }
        end
      end.sort_by { |x| x[:name] }
    end

    def operator_ids
      Operator.filter_by_country_ids(country_ids.pluck(:id)).active.with_translations.includes(:fmu_operators).map do |x|
        { id: x.id, name: x.name, fmus: x.fmu_operators.pluck(:fmu_id) }
      end.sort_by { |x| x[:name] }
    end

    def country_ids
      Country.active.with_translations.map do  |x|
        {
            id: x.id, iso: x.iso, name: x.name,
            operators: x.operators.pluck(:id).uniq,
            fmus: x.fmus.pluck(:id).uniq,
            forest_types: forest_types_by_country(x),
            required_operator_document_ids: x.required_operator_documents.pluck(:id).uniq
        }
      end.sort_by { |x| x[:name] }
    end

    def beautify_name(name)
      name.split(" ").each_with_index.map do |word, index|
        if index == 0
          word.capitalize
        else
          if word == word.upcase
            word
          else
            word.downcase
          end
        end
      end.join(" ")
    end

    def forest_types_by_country(country)
      country_forest_types = country.forest_types
      ConstForestTypes::FOREST_TYPES.map do |key, value|
        if  country_forest_types.include?(key.to_s)
          { key: key, id: value[:index], name: value[:label] }
        end
      end.compact
    end
  end
end
