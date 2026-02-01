function initializeTranslatedRow() {
  document.querySelectorAll(".translation-link").forEach(function(link) {
    link.addEventListener("click", function() {
      const locale = this.dataset.locale;
      const container = this.closest(".translated-attribute");

      // Hide all translation contents for this attribute
      container.querySelectorAll(".translation-content").forEach(function(content) {
        content.style.display = "none";
      });

      // Show the selected locale's content
      const targetContent = container.querySelector('.translation-content[data-locale="' + locale + '"]');
      if (targetContent) {
        targetContent.style.display = "";
      }

      // Update active link styling
      container.querySelectorAll(".translation-link").forEach(function(l) {
        l.classList.remove("active");
      });
      this.classList.add("active");
    });
  });
}

document.addEventListener("DOMContentLoaded", initializeTranslatedRow);
