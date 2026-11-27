// Styled replacement for the browser confirm() on data-confirm links and buttons (jquery_ujs).
// Returning false from jquery_ujs's "confirm" event stops the action; after "OK" it is replayed
// without data-confirm.
(function() {
  const escape = text => $('<div>').text(text).html();

  function buildDialog(destructive) {
    const labels = $('#admin-js-i18n').data() || {};
    const okLabel = destructive ? (labels.delete || 'Delete') : (labels.ok || 'OK');

    return $(`
      <dialog class="confirm-dialog">
        <form method="dialog">
          <p class="confirm-dialog__message"></p>
          <div class="confirm-dialog__actions">
            <button value="cancel" class="confirm-dialog__cancel">${escape(labels.cancel || 'Cancel')}</button>
            <button value="ok" class="confirm-dialog__ok ${destructive ? 'danger' : ''}">${escape(okLabel)}</button>
          </div>
        </form>
      </dialog>
    `).appendTo('body')[0];
  }

  function replay($element) {
    const message = $element.attr('data-confirm');
    $element.removeAttr('data-confirm').removeData('confirm');
    $element.is('form') ? $element.trigger('submit') : $element[0].click();
    $element.attr('data-confirm', message);
  }

  $(document).on('confirm', '[data-confirm]', function() {
    const $element = $(this);
    const destructive = String($element.data('method')).toLowerCase() === 'delete';
    const dialog = buildDialog(destructive);

    // set as text, never interpolated: messages can contain user-entered names
    dialog.querySelector('.confirm-dialog__message').textContent = $element.data('confirm');

    dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
    dialog.addEventListener('close', () => {
      dialog.remove();
      if (dialog.returnValue === 'ok') replay($element);
    });

    dialog.showModal();
    dialog.querySelector(destructive ? '.confirm-dialog__cancel' : '.confirm-dialog__ok').focus();
    return false;
  });
})();
