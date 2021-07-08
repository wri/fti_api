# frozen_string_literal: true

class ScoreOperatorDocumentDecorator < BaseDecorator
  def document_history_link
    h.link_to 'Documents', admin_operator_document_histories_path(
      q: {
        operator_document_updated_at_lteq_datetime: model.date,
        required_operator_document_contract_signature_eq: false,
        operator_id_eq: model.operator_id
      }
    )
  end

  # rubocop:disable Rails/OutputSafety
  def private_summary_diff(prev_score)
    return print_summary(model.summary_private).html_safe if prev_score.blank?

    print_diff(
      prev_score.summary_private,
      model.summary_private
    ).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  # rubocop:disable Rails/OutputSafety
  def public_summary_diff(prev_score)
    return print_summary(model.summary_public).html_safe if prev_score.blank?

    print_diff(
      prev_score.summary_public,
      model.summary_public
    ).html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def print_diff(prev, current)
    current.map do |key, value|
      color = nil
      if value > prev[key]
        color = 'green'
      elsif value < prev[key]
        color = 'red'
      end

      "#{key.gsub('doc_','')}: <span style='color: #{color}'>#{value}</span>"
    end.join('<br/>')
  end

  def print_summary(sum)
    sum.map do |key, value|
      "#{key.gsub('doc_','')}: #{value}"
    end.join('<br/>')
  end
end
