// Flash messages are shown as toasts (positioned in CSS). Success notices fade out on their own;
// alerts and errors stay until closed.
$(document).ready(function() {
  const container = document.querySelector('body.logged_in .flashes');
  if (!container) return;

  const closeLabel = ($('#admin-js-i18n').data() || {}).close || 'Close';
  const AUTO_DISMISS_MS = 5000;

  function dismiss(toast) {
    if (toast.classList.contains('is-leaving')) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      toast.remove();
      return;
    }
    toast.classList.add('is-leaving');
    const remove = () => toast.remove();
    toast.addEventListener('animationend', remove, { once: true });
    setTimeout(remove, 400);
  }

  container.querySelectorAll(':scope > .flash').forEach(toast => {
    const notice = toast.classList.contains('flash_notice');
    toast.setAttribute('role', notice ? 'status' : 'alert');

    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'flash__close';
    close.setAttribute('aria-label', closeLabel);
    close.title = closeLabel;
    close.innerHTML = '<svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" /></svg>';
    close.addEventListener('click', () => dismiss(toast));
    toast.append(close);

    if (!notice) return;

    let timer = setTimeout(() => dismiss(toast), AUTO_DISMISS_MS);
    toast.addEventListener('mouseenter', () => clearTimeout(timer));
    toast.addEventListener('mouseleave', () => { timer = setTimeout(() => dismiss(toast), AUTO_DISMISS_MS / 2); });
  });
});
