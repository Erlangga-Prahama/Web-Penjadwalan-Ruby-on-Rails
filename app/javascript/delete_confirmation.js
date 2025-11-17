// Initialize Flowbite Modal
let deleteModal;
let currentDeleteUrl;

document.addEventListener("DOMContentLoaded", function () {
  deleteModal = new Modal(document.getElementById("deleteModal"));

  // Confirm button handler
  document
    .getElementById("confirmDeleteBtn")
    .addEventListener("click", function () {
      if (currentDeleteUrl) {
        fetch(currentDeleteUrl, {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": document.querySelector("[name='csrf-token']")
              .content,
            Accept:
              "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
          },
          credentials: "same-origin",
        })
          .then((response) => {
            if (response.ok) {
              window.location.reload(); // Or handle Turbo Stream response
            }
          })
          .catch((error) => console.error("Error:", error));
      }
      deleteModal.hide();
    });

  // Cancel button handler
  document
    .getElementById("cancelDeleteBtn")
    .addEventListener("click", function () {
      deleteModal.hide();
    });
});

// Global function to show modal
window.showDeleteModal = function (event, url) {
  event.preventDefault();
  currentDeleteUrl = url;
  deleteModal.show();
};
