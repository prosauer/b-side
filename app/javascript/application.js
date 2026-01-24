import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import TidalSearchController from "./controllers/tidal_search_controller"

window.Stimulus = Application.start()
window.Stimulus.register("tidal-search", TidalSearchController)
