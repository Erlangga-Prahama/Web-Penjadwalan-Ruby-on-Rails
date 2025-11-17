// controllers/confirm_generate_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal", "spinner", "form"];

  showConfirm(event) {
    event.preventDefault();
    this.modalTarget.classList.remove("hidden");
  }

  confirm() {
    this.modalTarget.classList.add("hidden");
    this.spinnerTarget.classList.remove("hidden");
    this.formTarget.submit();
  }

  cancel() {
    this.modalTarget.classList.add("hidden");
  }
}
