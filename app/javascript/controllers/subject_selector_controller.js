import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "output"];

  connect() {
    this.updateText();
  }

  updateText() {
    const selectedSubjects = this.checkboxTargets
      .filter((cb) => cb.checked)
      .map(
        (cb) => cb.closest("li")?.querySelector("label")?.innerText.trim() || ""
      );

    this.outputTarget.innerText =
      selectedSubjects.length > 0 ? selectedSubjects.join(", ") : "Pilih Mapel";
  }
}
