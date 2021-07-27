$(document).ready(function() {
  $(".observation-checkbox").on('change', function(event) {
    const elem = event.target;
    const column = $(`.col-${elem.id}`);
    column.toggleClass('hide', !elem.checked);
    localStorage.setItem(elem.id, elem.checked);
  });

  if ($('.observation-attributes').length > 0) {
    $('.observation-attributes').children().each((_idx, elem) => {
      const id = elem.id.split('-')[1];
      const storage = localStorage.getItem(id);
      if (storage !== null) {
        if(storage === "true") {
          $('#' + id).prop("checked", true);
        } else {
          $('#' + id).prop("checked", false);
        }
      }
      const column = $(`.col-${id}`);
      column.toggleClass('hide', !$('#' + id).prop('checked'));
    })
  }
});
