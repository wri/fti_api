# frozen_string_literal: true

class ScoreOperatorDocumentDecorator < BaseDecorator
  def document_history_link
    h.link_to 'Documents', admin_operator_document_histories_path(
      q: {
        updated_at_lteq_datetime: model.date,
        required_operator_document_contract_signature_eq: false,
        operator_id_eq: model.operator_id
      }
    )
  end

  def summary_diff(prev_score)
    return print_summary(model.summary_private) if prev_score.blank?

    print_diff(
      prev_score.summary_private,
      model.summary_private
    ).html_safe
  end

  def print_diff(prev, current)
    current.map do |key, value|
      color = nil
      if value > prev[key]
        color = 'green'
      elsif value < prev[key]
        color = 'red'
      end

      "#{key.gsub('doc_','')}: <span style='color: #{color}'>#{value}</span>"
    end.join(', ')
  end

  def print_summary(s)
    s.map do |key, value|
      "#{key.gsub('doc_','')}: #{value}"
    end.join(', ')
  end
end
