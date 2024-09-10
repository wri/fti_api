$(document).ready(function() {
  updateQCFields();
  $('input[name="quality_control[passed]"]').on('change', function(){
    updateQCFields();
  })
})

function updateQCFields() {
  const selectedValue = $('input[name="quality_control[passed]"]:checked').val();
  const comment = $('#quality_control_comment_input');

  if (selectedValue === 'false') {
    comment.find('textarea').prop('disabled', false);
    comment.show();
  } else {
    comment.find('textarea').prop('disabled', true);
    comment.hide();
  }
}
