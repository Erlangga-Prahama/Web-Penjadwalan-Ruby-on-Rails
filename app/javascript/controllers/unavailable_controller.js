import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];

  connect() {
    this.allSelected = false;
  }

  toggleAll() {
    const checkboxes = this.element.querySelectorAll(".timeblock-checkbox");
    checkboxes.forEach((cb) => (cb.checked = !this.allSelected));
    this.allSelected = !this.allSelected;

    // Ubah teks tombol
    const btn = this.element.closest("div").querySelector("button");
    btn.textContent = this.allSelected ? "Batal Pilih Semua" : "Pilih Semua";
  }
}
