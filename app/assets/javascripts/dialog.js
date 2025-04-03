function initializeDialog() {
  document.querySelectorAll("dialog").forEach((dialog) => {
    // close when clicking outside
    dialog.addEventListener("mousedown", (event) => {
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
      button.addEventListener("click", () => {
        dialog.close();
      });
    });
  });
}

document.addEventListener("DOMContentLoaded", initializeDialog);
