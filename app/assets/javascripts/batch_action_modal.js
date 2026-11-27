// ActiveAdmin's batch action modal renders OK, Cancel; like the other dialogs, the primary action goes on the right.
$(document).on('modal_dialog:after_open', (_event, form) => {
  const $buttons = $(form).closest('.ui-dialog').find('.ui-dialog-buttonset');
  $buttons.prepend($buttons.children().last());
});
