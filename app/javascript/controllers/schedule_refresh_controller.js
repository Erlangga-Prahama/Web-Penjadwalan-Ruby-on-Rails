// app/javascript/controllers/schedule_refresh_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (window.location.search.includes("generating=true")) {
      this.startRefreshing();
    }
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      window.location.reload();
    }, 5000); // Refresh setiap 5 detik
  }

  disconnect() {
    clearInterval(this.refreshTimer);
  }
}
