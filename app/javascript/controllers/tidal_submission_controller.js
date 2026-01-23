import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "title", "artist", "cover", "coverPlaceholder", "status"]
  static values = { lookupUrl: String }

  async lookup() {
    const url = this.urlTarget.value.trim()
    if (!url) {
      this.resetPreview()
      return
    }

    this.statusTarget.textContent = "Looking up track details..."
    this.statusTarget.classList.remove("text-red-400")
    this.statusTarget.classList.add("text-gray-400")

    try {
      const response = await fetch(`${this.lookupUrlValue}?song_url=${encodeURIComponent(url)}`, {
        headers: { Accept: "application/json" }
      })
      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Unable to fetch track details.")
      }

      this.titleTarget.textContent = data.song_title || "Unknown title"
      this.artistTarget.textContent = data.artist || "Unknown artist"
      this.statusTarget.textContent = "Track found on TIDAL."
      this.statusTarget.classList.remove("text-red-400")
      this.statusTarget.classList.add("text-green-400")

      if (data.album_art_url) {
        this.coverTarget.src = data.album_art_url
        this.coverTarget.classList.remove("hidden")
        this.coverPlaceholderTarget.classList.add("hidden")
      } else {
        this.coverTarget.classList.add("hidden")
        this.coverPlaceholderTarget.classList.remove("hidden")
      }
    } catch (error) {
      this.resetPreview()
      this.statusTarget.textContent = error.message
      this.statusTarget.classList.remove("text-green-400")
      this.statusTarget.classList.add("text-red-400")
    }
  }

  resetPreview() {
    this.titleTarget.textContent = "Song title will appear here"
    this.artistTarget.textContent = "Artist will appear here"
    this.statusTarget.textContent = ""
    this.coverTarget.classList.add("hidden")
    this.coverPlaceholderTarget.classList.remove("hidden")
  }
}
