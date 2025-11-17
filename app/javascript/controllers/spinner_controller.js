import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["spinner"];

  showSpinner(event) {
    const confirmed = confirm("Yakin ingin generate jadwal baru?");
    if (!confirmed) {
      event.preventDefault(); // batalkan submit
      return;
    }

    this.spinnerTarget.classList.remove("hidden");
  }
}
