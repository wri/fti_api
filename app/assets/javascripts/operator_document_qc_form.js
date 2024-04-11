$(document).ready(function() {
  updatePerformQCFields();
  $('input[name="operator_document_qc_form[decision]"]').on('change', function(){
    updatePerformQCFields();
  })
})

function updatePerformQCFields() {
  const selectedValue = $('input[name="operator_document_qc_form[decision]"]:checked').val();
  const adminComment = $('#operator_document_qc_form_admin_comment_input');

  if (selectedValue === 'doc_invalid') {
    adminComment.find('textarea').prop('disabled', false);
    adminComment.show();
  } else {
    adminComment.find('textarea').prop('disabled', true);
    adminComment.hide();
  }
}
