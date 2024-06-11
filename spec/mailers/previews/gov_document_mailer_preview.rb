class GovDocumentMailerPreview < ActionMailer::Preview
  def expiring_documents
    GovDocumentMailer.expiring_documents country, test_user, documents
  end

  def expired_documents
    GovDocumentMailer.expired_documents country, test_user, documents
  end

  private

  def test_user
    User.new(email: "john@example.com", name: "John Tester", locale: "en")
  end

  def country
    Country.find_by(iso: "COD")
  end

  def documents
    [
      GovDocument.new(
        id: 1,
        start_date: 10.days.ago,
        expire_date: 2.years.from_now,
        required_gov_document: RequiredGovDocument.new(name: "Information on the pre-emptive right"),
        attachment: File.open(Rails.root.join("spec", "support", "files", "doc.pdf"))
      ),
      GovDocument.new(
        id: 2,
        start_date: 10.days.ago,
        expire_date: 2.years.from_now,
        required_gov_document: RequiredGovDocument.new(name: "List of annual operating permits/annual logging certificates issued"),
        attachment: File.open(Rails.root.join("spec", "support", "files", "doc.pdf"))
      )
    ]
  end
end
