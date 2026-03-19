function initializeDialog(root) {
  root.querySelectorAll("dialog").forEach((dialog) => {
    // close when clicking outside
    dialog.addEventListener("mousedown", (event) => {
      if (event.target !== dialog) return;
      // Check if the click is on the backdrop (not the dialog content)
      const dialogDimensions = dialog.getBoundingClientRect();
      if (
        event.clientX < dialogDimensions.left ||
        event.clientX > dialogDimensions.right ||
        event.clientY < dialogDimensions.top ||
        event.clientY > dialogDimensions.bottom
      ) {
        dialog.close();
      }
    });

    dialog.querySelectorAll(".close-dialog-button").forEach((button) => {
      if (button.closest("dialog") === dialog) {
        button.addEventListener("click", () => {
          dialog.close();
        });
      }
    });
  });
}

document.addEventListener("DOMContentLoaded", function() { initializeDialog(document); });
document.addEventListener("app:content_load", function(e) { initializeDialog(e.target); });
