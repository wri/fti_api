# frozen_string_literal: true

# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("user"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserPermission < ApplicationRecord
  enum user_role: {user: 0, operator: 1, ngo: 2, ngo_manager: 4,
                   bo_manager: 5, admin: 3, government: 6, holding: 7}.freeze

  belongs_to :user

  def permissions
    hash = JSON.parse(role_permissions.to_json)
    permissions_overwrite = read_attribute(:permissions)

    return hash if permissions_overwrite.blank?

    hash.merge(permissions_overwrite) { |_key, oldval, newval| newval } # keep only top level overwrite
  end

  def role_permissions
    case user_role
    when "admin"
      {admin: {manage: {}}, all: {manage: {}}}
    when "operator"
      {user: {manage: {id: user.id}},
       operator_document: {manage: {operator_id: user.operator_id}},
       operator_document_annex: {ud: {operator_document: {operator_id: user.operator_id}}, create: {}},
       observation: {read: {}},
       fmu: {ru: {}},
       operator: {ru: {id: user.operator_id}},
       sawmill: {create: {}, ud: {operator_id: user.operator_id}}}
    when "holding"
      {user: {manage: {id: user.id}},
       operator_document: {manage: {operator: {holding_id: user.holding_id}}},
       operator_document_annex: {ud: {operator_document: {operator: {holding_id: user.holding_id}}}, create: {}},
       observation: {read: {}},
       fmu: {ru: {}},
       operator: {ru: {holding_id: user.holding_id}},
       sawmill: {create: {}, ud: {operator: {holding_id: user.holding_id}}}}
    when "ngo"
      {user: {manage: {id: user.id}},
       observation: {manage: {observers: {id: user.all_managed_observer_ids}}, create: {}},
       observation_report: {update: {observers: {id: user.all_managed_observer_ids}}, create: {}},
       observation_documents: {ud: {observations: {is_active: false, observers: {id: user.all_managed_observer_ids}}}, create: {}},
       category: {read: {}},
       subcategory: {read: {}},
       government: {cru: {}},
       species: {read: {}},
       operator: {cru: {}},
       law: {read: {}},
       severity: {read: {}},
       observer: {read: {}, update: {id: user.all_managed_observer_ids}},
       fmu: {read: {}},
       operator_document: {read: {}},
       required_operator_document_group: {read: {}},
       required_operator_document: {read: {}}}
    when "ngo_manager"
      {
        user: {manage: {id: user.id}},
        observation: {manage: {observers: {id: user.all_managed_observer_ids}}, update: {observers: {id: user.reviewable_observer_ids}}, read: {}, create: {}},
        observation_report: {update: {observers: {id: user.all_managed_observer_ids}}, create: {}},
        observation_documents: {ud: {observations: {is_active: false, observers: {id: user.all_managed_observer_ids}}}, create: {}},
        category: {cru: {}},
        subcategory: {cru: {}},
        government: {cru: {}},
        species: {cru: {}},
        operator: {cru: {}},
        law: {cru: {}},
        severity: {cru: {}},
        observer: {read: {}, update: {id: user.all_managed_observer_ids}},
        fmu: {read: {}, update: {}},
        operator_document: {manage: {}},
        required_operator_document_group: {cru: {}},
        required_operator_document: {cru: {}},
        file_data_import: {manage: {}},
        quality_controls: {cru: {reviewable_id: user.quality_controlable_observations.pluck(:id), reviewable_type: "Observation"}}
      }
    when "bo_manager"
      {
        user: {manage: {id: user.id}},
        observation: {manage: {}},
        observer: {read: {}},
        operator: {read: {}},
        observation_report: {read: {}},
        observation_documents: {read: {}},
        category: {read: {}},
        subcategory: {read: {}},
        government: {read: {}},
        species: {read: {}},
        law: {read: {}},
        severity: {read: {}},
        fmu: {read: {}},
        operator_document: {read: {}},
        required_operator_document_group: {read: {}},
        required_operator_document: {read: {}},
        quality_controls: {cru: {reviewable_id: user.quality_controlable_observations.pluck(:id), reviewable_type: "Observation"}}
      }
    when "government"
      {
        user: {manage: {id: user.id}},
        gov_document: {rud: {country_id: user.country_id}, create: {}}
      }
    else
      {user: {current: {id: user.id}, read: {id: user.id}}, observations: {read: {}}}
    end
  end
end
