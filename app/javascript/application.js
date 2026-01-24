import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import TidalSearchController from "./controllers/tidal_search_controller"
import VotePointsController from "./controllers/vote_points_controller"

window.Stimulus = Application.start()
window.Stimulus.register("tidal-search", TidalSearchController)
window.Stimulus.register("vote-points", VotePointsController)
