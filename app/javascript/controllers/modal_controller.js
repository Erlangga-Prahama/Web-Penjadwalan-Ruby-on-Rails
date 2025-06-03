// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  open() {
    this.modalTarget.style.display = "block";
  }

  close() {
    this.modalTarget.style.display = "none";
  }
}
