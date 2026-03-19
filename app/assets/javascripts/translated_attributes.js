function initializeTranslatedAttributes(root) {
  root.querySelectorAll(".translation-link").forEach(function(link) {
    link.addEventListener("click", function() {
      const locale = this.dataset.locale;
      const container = this.closest(".translated-attribute");

      container.querySelectorAll(".translation-content").forEach(function(content) {
        content.style.display = "none";
      });

      const targetContent = container.querySelector('.translation-content[data-locale="' + locale + '"]');
      if (targetContent) {
        targetContent.style.display = "";
      }

      container.querySelectorAll(".translation-link").forEach(function(l) {
        l.classList.remove("active");
      });
      this.classList.add("active");
    });
  });
}

document.addEventListener("DOMContentLoaded", function() { initializeTranslatedAttributes(document); });
document.addEventListener("app:content_load", function(e) { initializeTranslatedAttributes(e.target); });
