$(document).ready(function() {
  const SKIP_CONTENT = 'input, select, textarea, button, .dropdown_menu, .tag-select-container, .table_actions';
  const wrapped = [];

  $('.index_as_table table.index_table > tbody > tr > td').each((_i, td) => {
    if (/(^|\s)col-(selectable|actions)(\s|$)/.test(td.className)) return;
    const length = td.textContent.trim().length;
    if (length < 16 || td.querySelector(SKIP_CONTENT)) return;

    const clamp = document.createElement('div');
    clamp.className = length >= 40 ? 'cell-clamp cell-clamp--long' : 'cell-clamp';
    while (td.firstChild) clamp.appendChild(td.firstChild);
    td.appendChild(clamp);
    wrapped.push(td);
  });

  // measure after all cells are wrapped, so layout is computed once
  wrapped.forEach(td => {
    const clamp = td.firstChild;
    if (clamp.scrollHeight > clamp.clientHeight + 1) td.classList.add('is-clamped');
  });

  $(document).on('click', '.index_as_table td.is-clamped', function(event) {
    if ($(event.target).closest('a, button, input, select, label').length) return;
    if (String(window.getSelection()).length) return;
    this.classList.toggle('is-expanded');
  });
});
