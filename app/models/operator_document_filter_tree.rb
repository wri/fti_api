# frozen_string_literal: true

class OperatorDocumentFilterTree
  delegate :to_json, to: :tree

  def tree
    @tree ||= {
      forest_types: forest_types,
      status: statuses,
      country_ids: country_ids,
      operator_id: operator_ids,
      fmu_id: fmu_ids,
      required_operator_document_id: required_operator_document_ids,
      source: sources,
      legal_categories: legal_categories
    }
  end

  private

  # labels are translated per request, constants would keep the locale of the first request after boot
  def statuses
    [
      {id: "doc_not_provided", name: I18n.t("operator_documents.filters.doc_not_provided")},
      {id: "doc_valid", name: I18n.t("operator_documents.filters.doc_valid")},
      {id: "doc_expired", name: I18n.t("operator_documents.filters.doc_expired")},
      {id: "doc_not_required", name: I18n.t("operator_documents.filters.doc_not_required")}
    ]
  end

  def sources
    [
      {id: 1, name: I18n.t("filters.company")},
      {id: 2, name: I18n.t("filters.forest_atlas")},
      {id: 3, name: I18n.t("filters.other")}
    ]
  end

  def legal_categories
    groups = RequiredOperatorDocumentGroup.with_translations.where.not(id: required_operator_group_id_to_exclude).to_a
    document_ids = group_values(
      RequiredOperatorDocument.where(required_operator_document_group_id: groups.map(&:id)),
      :required_operator_document_group_id, :id
    )

    groups.map do |x|
      {
        id: x.id,
        name: x.name,
        required_operator_document_ids: document_ids.fetch(x.id, []).sort
      }
    end.sort_by { |x| x[:name] }
  end

  def forest_types
    ForestType::TYPES.map do |key, value|
      {key: key, id: value[:index], name: ForestType.label(key)}
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
      .where(country_id: country_ids.pluck(:id))
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
    @country_ids ||= begin
      countries = Country.active.with_translations.to_a
      ids = countries.map(&:id)
      operators = group_values(Operator.where(country_id: ids), :country_id, :id)
      fmus = group_values(Fmu.where(country_id: ids), :country_id, :id)
      forest_types = group_values(Fmu.where(country_id: ids), :country_id, :forest_type)
      required_operator_documents = group_values(RequiredOperatorDocument.where(country_id: ids), :country_id, :id)
      required_operator_doc_ids_to_exclude = RequiredOperatorDocument
        .where(required_operator_document_group_id: required_operator_group_id_to_exclude)
        .pluck(:id)

      countries.map do |x|
        {
          id: x.id, iso: x.iso, name: x.name,
          operators: operators.fetch(x.id, []).sort,
          fmus: fmus.fetch(x.id, []).sort,
          forest_types: serialize_forest_types(forest_types.fetch(x.id, [])),
          required_operator_document_ids: (required_operator_documents.fetch(x.id, []) - required_operator_doc_ids_to_exclude).sort
        }
      end.sort_by { |x| x[:name] }
    end
  end

  # {key => distinct values} in one query instead of one query per key
  def group_values(relation, key, value)
    relation.distinct.pluck(key, value).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
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
      {key: key, id: value[:index], name: ForestType.label(key)} if forest_types.include?(key.to_s)
    end
  end

  def required_operator_group_id_to_exclude
    return @required_operator_group_id_to_exclude if defined?(@required_operator_group_id_to_exclude)

    @required_operator_group_id_to_exclude = RequiredOperatorDocumentGroup.with_translations("en").where(name: "Publication Authorization").first&.id
  end
end
