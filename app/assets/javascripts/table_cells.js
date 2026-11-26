// Long index cells are wrapped in .cell-clamp on the server (config/initializers/active_admin_table_cells.rb).
// Here we only mark the truncated ones and let them expand on click.
$(document).ready(function() {
  document.querySelectorAll('.index_as_table table.index_table > tbody > tr > td > .cell-clamp').forEach(clamp => {
    if (clamp.scrollHeight > clamp.clientHeight + 1) clamp.parentElement.classList.add('is-clamped');
  });

  $(document).on('click', '.index_as_table td.is-clamped', function(event) {
    if ($(event.target).closest('a, button, input, select, label').length) return;
    if (String(window.getSelection()).length) return;
    this.classList.toggle('is-expanded');
  });
});
