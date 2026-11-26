// Styled replacement for the browser confirm() on data-confirm links and buttons (jquery_ujs).
// Returning false from jquery_ujs's "confirm" event stops the action; after "OK" it is replayed
// without data-confirm. The dialog markup is rendered in custom_admin_header.rb.
$(document).on('confirm', '[data-confirm]', function() {
  const $element = $(this);
  const dialog = document.getElementById('confirm-dialog');
  if (!dialog) return true;

  const destructive = String($element.data('method')).toLowerCase() === 'delete';
  const ok = dialog.querySelector('.confirm-dialog__ok');
  ok.textContent = destructive ? ok.dataset.delete : ok.dataset.ok;
  ok.classList.toggle('danger', destructive);
  dialog.querySelector('.confirm-dialog__message').textContent = $element.data('confirm');
  dialog.returnValue = '';

  dialog.addEventListener('close', () => {
    if (dialog.returnValue !== 'ok') return;
    const message = $element.attr('data-confirm');
    $element.removeAttr('data-confirm').removeData('confirm');
    $element.is('form') ? $element.trigger('submit') : $element[0].click();
    $element.attr('data-confirm', message);
  }, { once: true });

  dialog.showModal();
  (destructive ? dialog.querySelector('.confirm-dialog__cancel') : ok).focus();
  return false;
});
