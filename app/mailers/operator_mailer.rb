class OperatorMailer < ApplicationMailer
  include ActionView::Helpers::DateHelper

  helper :date

  def expiring_documents_notifications(operator, documents)
    num_documents = documents.count
    expire_date = documents.first.expire_date
    if expire_date > Time.zone.today
      # expiring documents
      time_to_expire = distance_of_time_in_words(expire_date, Time.zone.today)
      subject = t("backend.mail_service.expiring_documents.title", count: num_documents) +
        time_to_expire
      text = [t("backend.mail_service.expiring_documents.text", company_name: operator.name, count: num_documents)]
      text << time_to_expire
      documents.each { |document| text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t("backend.mail_service.expiring_documents.salutation")
    else
      # expired documents
      subject = t("backend.mail_service.expired_documents.title", count: num_documents)
      text = [t("backend.mail_service.expired_documents.text", company_name: operator.name, count: num_documents)]
      documents.each { |document| text << "<br><a href='#{document_admin_url(document)}'>#{document&.required_operator_document&.name}</a>" }
      text << t("backend.mail_service.expired_documents.salutation")
    end

    mail to: operator.email,
      subject: subject,
      body: text.join(""),
      content_type: "text/html"
  end

  def expiring_documents(operator, user, documents)
    @documents = documents.sort_by { |d| [d.fmu&.name || "_", d.required_operator_document.name] }
    @user = user
    @operator = operator
    days_to_expire = distance_of_time_in_words(documents.first.expire_date, Time.zone.today)

    mail to: user.email,
      subject: I18n.t("operator_mailer.expiring_documents.subject", count: @documents.count, days: days_to_expire)
  end

  def expired_documents(operator, user, documents)
    @documents = documents.sort_by { |d| [d.fmu&.name || "_", d.required_operator_document.name] }
    @user = user
    @operator = operator

    mail to: user.email, subject: I18n.t("operator_mailer.expired_documents.subject", count: @documents.count)
  end

  # An email that contains the a quarterly report of an operator
  # It lists:
  # 1. Current transparency score
  # 2. Change of score in the last quarter
  # 3. List of documents expiring in the next quarter
  # It's sent every quarter to all users of an operator
  def quarterly_newsletter(operator, user)
    return if operator.users.filter_actives.empty?
    return if user.nil?
    raise "User is not eligible to receive this newsletter" unless operator.users.filter_actives.include?(user)

    @user = user
    current_score = operator.score_operator_document
    last_score = operator.score_operator_documents.at_date(Time.zone.today - 3.months).order(:date).last
    @expiring_docs = operator.operator_documents.to_expire(Time.zone.today + 3.months)

    @score = begin
      NumberHelper.float_to_percentage(current_score.all)
    rescue
      0
    end

    if last_score.present?
      @old_score = begin
        NumberHelper.float_to_percentage(last_score.all)
      rescue
        0
      end
      @old_score_date = last_score.date
      @score_variation = NumberHelper.float_to_percentage(current_score.all - last_score.all)
    end

    mail to: user.email, subject: I18n.t("operator_mailer.quarterly_newsletter.subject")
  end

  private

  def document_admin_url(document)
    ENV["APP_URL"] + Rails.application.routes.url_helpers.url_for(
      {
        controller: "admin/operator_documents",
        action: "show",
        id: document.id,
        only_path: true
      }
    )
  end
end
