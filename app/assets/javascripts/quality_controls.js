$(document).ready(function() {
  updateQCFields();
  $('input[name="quality_control[decision]"]').on('change', function(){
    updateQCFields();
  })
})

function updateQCFields() {
  const selectedValue = $('input[name="quality_control[decision]"]:checked').val();
  const rejectableDecisions = $('#quality_control_rejectable_decisions').val().split(',');
  const comment = $('#quality_control_comment_input');

  if (rejectableDecisions.includes(selectedValue)) {
    comment.find('textarea').prop('disabled', false);
    comment.show();
  } else {
    comment.find('textarea').prop('disabled', true);
    comment.hide();
  }
}
