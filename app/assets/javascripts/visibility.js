$(document).on('ready', function() {

  $(".observation-checkbox").on('change', function(elem) {
    const id = ".col-" + elem.target.id;
    const column = $(id)
    if (elem.target.checked === true ) {
      column.removeClass('hide')
    } else {
      column.addClass('hide')
    }
  })
});