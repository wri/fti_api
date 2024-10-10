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

  function changeNonConcessionActivity() {
    const countrySelect = $('#observation_country_id');
    const operatorSelect = $('#observation_operator_id');
    const fmuSelect = $('#observation_fmu_id');

    const nonConcessionActivity = $('#observation_non_concession_activity');

    if (nonConcessionActivity.is(':checked')) {
      fmuSelect.data('parent', 'country_id');
      fmuSelect.data('parent-id', countrySelect.val());
    } else {
      fmuSelect.data('parent', 'operator_id');
      fmuSelect.data('parent-id', operatorSelect.val());
    }

    // TODO: this is workaround for active admin addon nested select to reinitialize the select2
    // make sure when updating the active admin addon to check if this is still working
    document.dispatchEvent(new Event('has_many_add:after'));
  }
  $('#observation_non_concession_activity').on('change', changeNonConcessionActivity);
})


