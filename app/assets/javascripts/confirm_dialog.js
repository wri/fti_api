// Replaces the browser's confirm() for data-confirm links and buttons (jquery_ujs) with a styled dialog.
// jquery_ujs expects a synchronous answer, so the action is stopped, and replayed once the user confirms.
(function() {
  const rails = $.rails;
  const i18n = () => $('#confirm-dialog-i18n').data() || {};

  function replay($element) {
    $element.data('confirm-dialog-accepted', true);
    if ($element.is('form')) {
      $element.trigger('submit');
    } else {
      $element[0].click();
    }
  }

  function open(message, $element) {
    const destructive = String($element.data('method')).toLowerCase() === 'delete';
    const labels = i18n();

    const dialog = document.createElement('dialog');
    dialog.className = 'confirm-dialog';
    const text = document.createElement('p');
    text.className = 'confirm-dialog__message';
    text.textContent = message;
    const actions = document.createElement('div');
    actions.className = 'confirm-dialog__actions';
    const ok = document.createElement('button');
    ok.type = 'button';
    ok.className = destructive ? 'confirm-dialog__ok danger' : 'confirm-dialog__ok';
    ok.textContent = destructive ? (labels.delete || 'Delete') : (labels.ok || 'OK');
    const cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.className = 'confirm-dialog__cancel';
    cancel.textContent = labels.cancel || 'Cancel';
    actions.append(cancel, ok);
    dialog.append(text, actions);
    document.body.appendChild(dialog);

    let answer = false;
    ok.addEventListener('click', () => { answer = true; dialog.close(); });
    cancel.addEventListener('click', () => dialog.close());
    dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
    dialog.addEventListener('close', () => {
      dialog.remove();
      if (rails.fire($element, 'confirm:complete', [answer]) && answer) replay($element);
    });

    dialog.showModal();
    (destructive ? cancel : ok).focus();
  }

  // ActiveAdmin's batch action modal renders OK, Cancel; dialogs keep the primary action on the right
  $(document).on('modal_dialog:after_open', (_event, form) => {
    const $buttons = $(form).closest('.ui-dialog').find('.ui-dialog-buttonset');
    $buttons.prepend($buttons.children().last());
  });

  rails.allowAction = function($element) {
    const message = $element.data('confirm');
    if (!message) return true;

    if ($element.data('confirm-dialog-accepted')) {
      $element.removeData('confirm-dialog-accepted');
      return true;
    }

    if (rails.fire($element, 'confirm')) open(message, $element);
    return false;
  };
})();
