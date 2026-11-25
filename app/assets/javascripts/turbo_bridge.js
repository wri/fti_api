// Turbo Drive glue: Turbo is loaded as a separate module (see config/initializers/active_admin.rb).
(function() {
  const callbacks = [];
  let initialLoad = true;

  // Run fn once per page: on the initial load and after every Turbo visit.
  window.onPageLoad = function(fn) {
    callbacks.push(fn);
    $(fn);
  };

  document.addEventListener("turbo:load", function() {
    // the initial page is already handled by DOM ready handlers
    if (initialLoad) {
      initialLoad = false;
      window.Turbo.config.forms.mode = "off";
      return;
    }

    // ActiveAdmin core and the quill editor only listen for the Turbolinks event
    document.dispatchEvent(new Event("turbolinks:load"));
    callbacks.forEach(function(fn) { fn(); });
  });
})();
