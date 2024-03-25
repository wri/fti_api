$(document).ready(function() {
  function changeFieldVisibility() {
    const evidenceType = $('#observation_evidence_type').val();
    const evidenceOnReportInput = $('#observation_evidence_on_report');
    const observationDocumentsSelect = $('#observation_observation_document_ids');

    const showInput = (input) => {
      input.prop('disabled', false);
      input.parent().show();
    };
    const hideInput = (input) => {
      input.prop('disabled', true);
      input.parent().hide();
    };

    hideInput(evidenceOnReportInput);
    hideInput(observationDocumentsSelect);

    switch (evidenceType) {
      case 'Uploaded documents':
        showInput(observationDocumentsSelect);
        break;
      case 'Evidence presented in the report':
        showInput(evidenceOnReportInput);
        break;
    }
  }

  changeFieldVisibility();
  $('#observation_evidence_type').on('change', changeFieldVisibility);
})


