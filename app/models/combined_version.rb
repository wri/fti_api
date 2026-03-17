# frozen_string_literal: true

# Wraps one logical "change event" which may consist of a parent model version,
# one or more translation versions, or both — grouped by the same author within
# a short time window. Used in the version history UI instead of raw PaperTrail
# versions so that translation-only changes are visible alongside model changes.
class CombinedVersion
  GROUPING_WINDOW_SECONDS = 5

  attr_reader :parent_version, :translation_versions
  attr_accessor :previous # set by build_for to link adjacent combined versions

  # Returns [Array<CombinedVersion>, PaperTrail::Version (create event)]
  def self.build_for(record)
    parent_versions = record.versions.to_a
    translation_versions = translation_versions_for(record)

    create_version = parent_versions.find { |v| v.event == "create" }
    non_create = (parent_versions + translation_versions)
      .reject { |v| v == create_version }
      .sort_by(&:created_at)

    combined = group(non_create)
    combined.each_cons(2) { |a, b| b.previous = a }

    [combined, create_version]
  end

  def self.translation_versions_for(record)
    return [] unless record.class.respond_to?(:translation_class)
    return [] if record.translation_ids.empty?

    PaperTrail::Version.where(
      item_type: record.class.translation_class.name,
      item_id: record.translation_ids
    ).to_a
  end

  def self.group(versions)
    versions.each_with_object([]) do |version, combined|
      match = combined.reverse_each.find { |c| c.can_absorb?(version) }
      match ? match.add(version) : combined << new(version)
    end
  end

  def initialize(first_version)
    @parent_version = nil
    @translation_versions = []
    add(first_version)
  end

  def add(version)
    if translation_version?(version)
      @translation_versions << version
    else
      @parent_version = version
    end
  end

  def can_absorb?(version)
    whodunnit == version.whodunnit &&
      (created_at - version.created_at).abs <= GROUPING_WINDOW_SECONDS
  end

  def created_at
    primary_version.created_at
  end

  def whodunnit
    primary_version.whodunnit
  end

  def event
    parent_version&.event || translation_versions.first&.event
  end

  def changeset
    parent_cs = parent_version&.changeset || {}
    translation_cs = translation_versions.each_with_object({}) do |v, h|
      # create events have locale in changeset; update/destroy don't (it never changes),
      # so fall back to reify which parses v.object without a DB query.
      # that is super weird but ok
      locale = v.changeset["locale"]&.last || v.reify&.locale
      next unless locale
      v.changeset.except("created_at", "updated_at", "id", "locale").each do |field, changes|
        next if field.end_with?("_id")
        h["#{field} (#{locale})"] = changes
      end
    end
    parent_cs.merge(translation_cs).except("created_at", "updated_at", "id")
  end

  def translation_only?
    parent_version.nil?
  end

  # Restores the record to the state it was in just BEFORE this combined version
  # (i.e. the state AFTER the previous combined version — matching PaperTrail's
  # reify semantics so the existing prev/next navigation in the UI still works).
  def reify(record)
    resource = if parent_version
      parent_version.reify
    else
      # translation-only change: restore parent from its most recent version before this timestamp
      parent_v = PaperTrail::Version
        .where(item_type: record.class.base_class.name, item_id: record.id)
        .where("created_at < ?", created_at)
        .order(created_at: :desc)
        .first
      parent_v ? parent_v.reify : record.dup
    end

    reify_translations!(resource, record)
    resource.id ||= record.id
    resource
  end

  private

  def primary_version
    parent_version || translation_versions.first
  end

  def translation_version?(version)
    version.item_type.end_with?("::Translation")
  end

  def reify_translations!(resource, record)
    return unless record.class.respond_to?(:translation_class)

    translation_class = record.class.translation_class
    record.translations.find_each do |translation|
      t_version = PaperTrail::Version
        .where(item_type: translation_class.name, item_id: translation.id)
        .where("created_at < ?", created_at)
        .order(created_at: :desc)
        .first
      next unless t_version

      reified_t = t_version.reify
      next unless reified_t

      locale = reified_t.locale.to_sym
      attrs = reified_t.attributes.slice(*record.class.translated_attribute_names.map(&:to_s))
      resource.translation_for(locale).assign_attributes(attrs)
    end
  end
end
