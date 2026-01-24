import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["score", "remaining", "submit", "helper"]
  static values = {
    totalPoints: Number,
    maxPerSong: Number
  }

  connect() {
    this.updateTotals()
  }

  increment(event) {
    const input = this.findScoreInput(event)
    if (!input) return

    const current = this.parseValue(input.value)
    if (current >= this.maxPerSongValue) return
    if (this.remainingPoints() <= 0) return

    input.value = current + 1
    this.updateTotals()
  }

  decrement(event) {
    const input = this.findScoreInput(event)
    if (!input) return

    const current = this.parseValue(input.value)
    if (current <= 0) return

    input.value = current - 1
    this.updateTotals()
  }

  findScoreInput(event) {
    const submissionId = event.currentTarget.dataset.submissionId
    return this.scoreTargets.find((input) => input.dataset.submissionId === submissionId)
  }

  updateTotals() {
    const remaining = this.remainingPoints()
    if (this.hasRemainingTarget) {
      this.remainingTarget.textContent = remaining
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = remaining !== 0
    }

    if (this.hasHelperTarget) {
      if (remaining === 0) {
        this.helperTarget.textContent = "All points allocated. You can submit your votes."
      } else {
        this.helperTarget.textContent = `Allocate all ${this.totalPointsValue} points to enable submission.`
      }
    }
  }

  remainingPoints() {
    const totalUsed = this.scoreTargets.reduce((sum, input) => sum + this.parseValue(input.value), 0)
    return Math.max(this.totalPointsValue - totalUsed, 0)
  }

  parseValue(value) {
    const parsed = parseInt(value, 10)
    return Number.isNaN(parsed) ? 0 : parsed
  }
}
