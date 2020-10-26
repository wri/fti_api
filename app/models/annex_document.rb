class AnnexDocument < ApplicationRecord
  belongs_to :documentable, polymorphic: true
  belongs_to :operator_document_annex
end