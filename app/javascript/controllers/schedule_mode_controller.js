import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "weekdays", "intervals"]

  connect() {
    this.update()
  }

  update() {
    const mode = this.selectTarget.value
    const showWeekdays = mode === "weekdays"
    const showIntervals = mode === "intervals"

    this.weekdaysTarget.classList.toggle("hidden", !showWeekdays)
    this.intervalsTarget.classList.toggle("hidden", !showIntervals)
  }
}
