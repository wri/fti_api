$(document).ready(function() {

  $(".observation-checkbox").on('change', function(elem) {
    const id = ".col-" + elem.target.id;
    const column = $(id)
    if (elem.target.checked === true ) {
      column.removeClass('hide')
      localStorage.setItem(elem.target.id, true)
    } else {
      column.addClass('hide')
      localStorage.setItem(elem.target.id, false)
    }
  })

  if ($('.observation-attributes').length > 0) {
    Array.from($('.observation-attributes').children()).forEach(elem => {
      const id = elem.id.split('-')[1];
      const storage = localStorage.getItem(id);
      if (storage !== null) {
        if(storage === "true") {
          $('#' + id).prop("checked", true);
        } else {
          $('#' + id).prop("checked", false);
          const column = $('.col-' + id)
          column.addClass('hide')
        }
      }
    });
  }
});