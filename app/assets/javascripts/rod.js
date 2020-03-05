$(document).ready(function() {
  updateFields();
  $('#required_operator_document_type_input').on('change', function(){
    updateFields();
  })
})

function updateFields() {
  var type = $('#required_operator_document_type').val();
  var forestType = $('#required_operator_document_forest_type');

  if (type === 'RequiredOperatorDocumentFmu') {
    forestType.prop('disabled', false);
    forestType.parent().show();
  } else
  {
    forestType.prop('disabled', true);
    forestType.parent().hide();
  }
}