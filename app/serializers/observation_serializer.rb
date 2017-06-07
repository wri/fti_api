# frozen_string_literal: true
# == Schema Information
#
# Table name: observations
#
#  id                  :integer          not null, primary key
#  annex_operator_id   :integer
#  annex_governance_id :integer
#  severity_id         :integer
#  observation_type    :string           not null
#  user_id             :integer
#  publication_date    :datetime
#  country_id          :integer
#  observer_id         :integer
#  operator_id         :integer
#  government_id       :integer
#  pv                  :string
#  is_active           :boolean          default(TRUE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  lat                 :decimal(, )
#  lng                 :decimal(, )
#  fmu_id              :integer
#

class ObservationSerializer < ActiveModel::Serializer
  attributes :id, :observation_type, :publication_date,
             :pv, :is_active, :details, :evidence, :concern_opinion, :litigation_status, :lat, :lng

  belongs_to :country,          serializer: CountrySerializer
  belongs_to :annex_operator,   serializer: AnnexOperatorSerializer
  belongs_to :annex_governance, serializer: AnnexGovernanceSerializer
  belongs_to :severity,         serializer: SeveritySerializer
  belongs_to :user,             serializer: UserSerializer
  belongs_to :observer,         serializer: ObserverSerializer
  belongs_to :operator,         serializer: OperatorSerializer
  belongs_to :government,       serializer: GovernmentSerializer

  has_many :species,   serializer: SpeciesSerializer
  has_many :comments,  serializer: CommentSerializer
  has_many :photos,    serializer: PhotoSerializer
  has_many :documents, serializer: DocumentSerializer
end
