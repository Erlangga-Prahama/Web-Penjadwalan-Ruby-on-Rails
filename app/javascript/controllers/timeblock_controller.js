import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["daySelect", "gradeSelect", "timeblock"];

  connect() {
    this.update();
  }

  update() {
    const selectedDay = this.daySelectTarget.value.toLowerCase();
    const selectedGrade = this.gradeSelectTarget.value;

    this.timeblockTargets.forEach((block) => {
      const blockDay = block.dataset.day.toLowerCase();
      const blockSession = block.dataset.session;

      const showForDay = blockDay === selectedDay;
      const showForGrade =
        (selectedGrade === "7" && blockSession === "siang") ||
        ((selectedGrade === "8" || selectedGrade === "9") &&
          blockSession === "pagi");

      block.classList.toggle("hidden", !(showForDay && showForGrade));
    });
  }
}
