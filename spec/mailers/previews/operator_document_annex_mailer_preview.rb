class OperatorDocumentAnnexMailerPreview < ActionMailer::Preview
  def document_valid
    OperatorDocumentAnnexMailer.document_valid valid_document, test_user
  end

  def document_invalid
    OperatorDocumentAnnexMailer.document_invalid invalid_document, test_user
  end

  def admin_document_pending
    OperatorDocumentAnnexMailer.admin_document_pending pending_document, test_user
  end

  private

  def pending_document
    valid_document.tap do |d|
      d.status = "doc_pending"
    end
  end

  def invalid_document
    valid_document.tap do |d|
      d.status = "doc_invalid"
      d.invalidation_reason = "Document is invalid because of reasons."
    end
  end

  def valid_document
    OperatorDocumentAnnex.new(
      id: 1,
      operator_document: operator_document,
      name: "CITES permits annex",
      start_date: 10.days.ago,
      expire_date: 2.years.from_now,
      attachment: File.open(Rails.root.join("spec", "support", "files", "doc.pdf")),
      status: "doc_valid"
    )
  end

  def operator_document
    OperatorDocumentFmu.new(
      id: 1,
      start_date: 10.days.ago,
      expire_date: 2.years.from_now,
      fmu: Fmu.new(name: "Ngombe"),
      operator: operator,
      required_operator_document: RequiredOperatorDocument.new(name: "CITES permits"),
      document_file: DocumentFile.new(attachment: File.open(Rails.root.join("spec", "support", "files", "doc.pdf"))),
      status: "doc_valid"
    )
  end

  def test_user
    User.new(email: "john@example.com", first_name: "John", last_name: "Tester", locale: "en")
  end

  def operator
    Operator.new(name: "IFO / Interholco", slug: "ifo-interholco")
  end
end
