function initializeVersionHistory(root) {
  root.querySelectorAll('.vh-toggle a[data-mode]').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var mode = this.dataset.mode;
      var container = this.closest('.vh-container');
      container.dataset.vhMode = mode;
      container.querySelectorAll('.vh-toggle a').forEach(function(a) {
        a.classList.toggle('active', a === link);
      });
    });
  });
}

document.addEventListener('DOMContentLoaded', function() { initializeVersionHistory(document); });
document.addEventListener('app:content_load', function(e) { initializeVersionHistory(e.target); });
