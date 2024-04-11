class OperatorDocumentMailerPreview < ActionMailer::Preview
  def expiring_documents
    OperatorDocumentMailer.expiring_documents operator, test_user, documents
  end

  def expired_documents
    OperatorDocumentMailer.expired_documents operator, test_user, documents
  end

  def document_valid
    OperatorDocumentMailer.document_valid valid_document, test_user
  end

  def document_accepted_as_not_required
    OperatorDocumentMailer.document_accepted_as_not_required valid_document, test_user
  end

  def document_invalid
    OperatorDocumentMailer.document_invalid invalid_document, test_user
  end

  private

  def invalid_document
    valid_document.tap do |d|
      d.status = "doc_invalid"
      d.admin_comment = "Document is invalid because of reasons."
    end
  end

  def valid_document
    OperatorDocumentFmu.new(
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
    User.new(email: "john@example.com", name: "John Tester", locale: "en")
  end

  def documents
    [
      OperatorDocumentFmu.new(
        expire_date: 7.days.from_now,
        fmu: Fmu.new(name: "00-100"),
        required_operator_document: RequiredOperatorDocument.new(name: "CITES permits")
      ),
      OperatorDocumentFmu.new(
        expire_date: 7.days.from_now,
        fmu: Fmu.new(name: "Ngombe"),
        required_operator_document: RequiredOperatorDocument.new(name: "Required trading and transport permits")
      )
    ]
  end

  def operator
    Operator.new(name: "IFO / Interholco", slug: "ifo-interholco")
  end
end
