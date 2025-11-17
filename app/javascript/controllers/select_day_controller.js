import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  change(event) {
    const selectedDay = event.target.value;

    fetch(`/activities/time_blocks_for_day?day=${selectedDay}`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
      },
    });
  }
}
