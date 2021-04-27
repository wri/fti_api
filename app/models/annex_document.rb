# frozen_string_literal: true

# == Schema Information
#
# Table name: annex_documents
#
#  id                         :integer          not null, primary key
#  documentable_type          :string           not null
#  documentable_id            :integer          not null
#  operator_document_annex_id :integer          not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class AnnexDocument < ApplicationRecord
  belongs_to :documentable, polymorphic: true
  belongs_to :operator_document_annex
  
end
