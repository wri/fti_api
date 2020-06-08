$(document).ready(function() {

  var goto_page_val = $("#hidden_active_admin_per_page").val();

  $("#hidden_active_admin_per_page").remove();

  $("form.filter_form").prepend(' \
    <div class="input optional filter_form_field " id="goto_page_input"> \
    <label for="page" class="label">Jump to page</label> \
  <input name="page" id="hidden_active_admin_goto_page" type="number"> \
    </div>');

  if (typeof goto_page_val !== 'undefined') {
    $("#hidden_active_admin_per_page").val(goto_page_val);
  }
});