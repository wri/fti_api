class ObserverMailer < ApplicationMailer
  def observation_status_changed(observer, user, observation)
    I18n.with_locale(user.locale.presence || :en) do
      infractor_text = if observation.observation_type == 'government'
                         t('backend.mail_service.observer_status_changed.government')
                       else
                         t('backend.mail_service.observer_status_changed.producers') + "#{observation.operator&.name}"
                       end

      @body = t('backend.mail_service.observer_status_changed.text',
                id: observation.id, observer: observer.name, status: observation.validation_status,
                status_fr: I18n.t("activerecord.enums.observation.statuses.#{observation.validation_status}", locale: :fr),
                date: observation.publication_date, infractor_text: infractor_text,
                infraction: observation.subcategory&.name,
                infraction_fr: Subcategory.with_translations(:fr).where(id: observation.subcategory_id).pluck(:name)&.first)

      mail to: user.email,
           subject: t('backend.mail_service.observer_status_changed.subject'),
           body: @body,
           content_type: 'text/plain'
    end
  end
end
