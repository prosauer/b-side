import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input",
    "suggestions",
    "selected",
    "error",
    "embed",
    "songTitleField",
    "artistField",
    "urlField",
    "tidalIdField"
  ]

  connect() {
    console.log("[tidal-search] connected", this.element)
    this.debounceTimer = null
  }

  search() {
    console.log("[tidal-search] search fired", this.inputTarget.value)
    this.clearSelection()
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchSuggestions(), 250)
  }

  close(event) {
    // Use contains() for input too (click may land on input wrapper)
    if (!this.suggestionsTarget.contains(event.target) && !this.inputTarget.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  validate(event) {
    if (!this.tidalIdFieldTarget.value) {
      event.preventDefault()
      this.errorTarget.classList.remove("hidden")
      this.inputTarget.focus()
    }
  }

  select(event) {
    const track = event.currentTarget.dataset
    this.inputTarget.value = `${track.title} - ${track.artist}`
    this.setSelection(track)
    this.hideSuggestions()
  }

  async fetchSuggestions() {
    const query = this.inputTarget.value.trim()
    if (query.length < 2) {
      this.hideSuggestions()
      this.clearSelection()
      return
    }

    const url = this.element.dataset.tidalSearchUrl
    console.log("[tidal-search] fetching", url, query)

    if (!url) {
      console.warn("[tidal-search] missing data-tidal-search-url on the controller element")
      return
    }

    try {
      const response = await fetch(`${url}?query=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.renderSuggestions(data.tracks || [])
    } catch (error) {
      console.warn("[tidal-search] fetch error", error)
      this.hideSuggestions()
    }
  }

  renderSuggestions(tracks) {
    this.suggestionsTarget.innerHTML = ""
    if (!tracks.length) {
      this.hideSuggestions()
      return
    }

    tracks.forEach((track) => {
      const button = document.createElement("button")
      button.type = "button"
      button.dataset.action = "click->tidal-search#select"
      button.dataset.id = track.id
      button.dataset.title = track.title
      button.dataset.artist = track.artist
      button.dataset.album = track.album || ""
      button.dataset.url = track.url
      button.dataset.imageUrl = track.image_url || ""
      button.className =
        "w-full text-left px-4 py-3 hover:bg-gray-800 border-b border-gray-800 last:border-b-0"
      button.innerHTML = `
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 bg-gray-800 rounded-md overflow-hidden flex-shrink-0">
            ${track.image_url ? `<img src="${track.image_url}" alt="" class="w-full h-full object-cover" />` : ""}
          </div>
          <div>
            <p class="font-semibold">${track.title}</p>
            <p class="text-sm text-gray-400">${track.artist}${track.album ? ` • ${track.album}` : ""}</p>
          </div>
        </div>
      `
      this.suggestionsTarget.appendChild(button)
    })

    this.suggestionsTarget.classList.remove("hidden")
  }

  setSelection(track) {
    this.songTitleFieldTarget.value = track.title
    this.artistFieldTarget.value = track.artist
    this.urlFieldTarget.value = track.url
    this.tidalIdFieldTarget.value = track.id
    this.embedTarget.src = `https://embed.tidal.com/tracks/${track.id}`
    this.selectedTarget.classList.remove("hidden")
    this.errorTarget.classList.add("hidden")
  }

  clearSelection() {
    this.songTitleFieldTarget.value = ""
    this.artistFieldTarget.value = ""
    this.urlFieldTarget.value = ""
    this.tidalIdFieldTarget.value = ""
    this.embedTarget.src = ""
    this.selectedTarget.classList.add("hidden")
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add("hidden")
  }
}
