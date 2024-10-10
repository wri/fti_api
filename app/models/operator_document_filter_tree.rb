# frozen_string_literal: true

class OperatorDocumentFilterTree
  delegate :to_json, to: :tree

  def tree
    @tree ||= {
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

  private

  TYPES = [
    {id: "OperatorDocumentCountry", name: I18n.t("operator_documents.filters.producer")},
    {id: "OperatorDocumentFmu", name: I18n.t("operator_documents.filters.fmu")}
  ].freeze

  STATUSES = [
    {id: "doc_not_provided", name: I18n.t("operator_documents.filters.doc_not_provided")},
    {id: "doc_valid", name: I18n.t("operator_documents.filters.doc_valid")},
    {id: "doc_expired", name: I18n.t("operator_documents.filters.doc_expired")},
    {id: "doc_not_required", name: I18n.t("operator_documents.filters.doc_not_required")}
  ].freeze

  SOURCES = [
    {id: 1, name: I18n.t("filters.company")},
    {id: 2, name: I18n.t("filters.forest_atlas")},
    {id: 3, name: I18n.t("filters.other")}
  ].freeze

  def legal_categories
    RequiredOperatorDocumentGroup.with_translations.where.not(id: required_operator_group_id_to_exclude).map do |x|
      {
        id: x.id,
        name: x.name,
        required_operator_document_ids: x.required_operator_documents.pluck(:id).sort
      }
    end.sort_by { |x| x[:name] }
  end

  def forest_types
    ForestType::TYPES.map do |key, value|
      {key: key, id: value[:index], name: value[:label]}
    end.sort_by { |x| x[:name] }
  end

  def fmu_ids
    Fmu.order(:name).pluck(:id, :name).map { |x| {id: x[0], name: x[1]} }
  end

  def required_operator_document_ids
    # TODO: after fixing bad data remove that filter
    # required operator document should always have a country, I think
    RequiredOperatorDocument
      .with_translations
      .where.not(country_id: nil)
      .where.not(required_operator_document_group_id: required_operator_group_id_to_exclude)
      .map do |x|
        {id: x.id, name: beautify_name(x.name)}
      end.sort_by { |x| x[:name] }
  end

  def operator_ids
    fmu_forest_types = Fmu.pluck(:id, :forest_type).to_h

    Operator
      .filter_by_country_ids(country_ids.pluck(:id))
      .active.fa_operator
      .includes(:fmu_operators).map do |x| # Beware includes :fmus is pretty slow, something with translations
        fmu_ids = x.fmu_operators.pluck(:fmu_id).sort
        {
          id: x.id,
          name: x.name,
          fmus: fmu_ids,
          forest_types: serialize_forest_types(
            fmu_forest_types.slice(*fmu_ids).values.uniq
          )
        }
      end.sort_by { |x| x[:name] }
  end

  def country_ids
    required_operator_doc_ids_to_exclude = RequiredOperatorDocument
      .where(required_operator_document_group_id: required_operator_group_id_to_exclude)
      .pluck(:id)

    Country.active.with_translations.map do |x|
      {
        id: x.id, iso: x.iso, name: x.name,
        operators: x.operators.pluck(:id).uniq.sort,
        fmus: x.fmus.pluck(:id).uniq.sort,
        forest_types: serialize_forest_types(x.forest_types),
        required_operator_document_ids: (x.required_operator_documents.pluck(:id).uniq - required_operator_doc_ids_to_exclude).sort
      }
    end.sort_by { |x| x[:name] }
  end

  def beautify_name(name)
    name.split(" ").each_with_index.map do |word, index|
      if index.zero?
        word.capitalize
      elsif word == word.upcase
        word
      else
        word.downcase
      end
    end.join(" ")
  end

  def serialize_forest_types(forest_types)
    ForestType::TYPES.filter_map do |key, value|
      {key: key, id: value[:index], name: value[:label]} if forest_types.include?(key.to_s)
    end
  end

  private

  def required_operator_group_id_to_exclude
    RequiredOperatorDocumentGroup.with_translations("en").where(name: "Publication Authorization").first&.id
  end
end
