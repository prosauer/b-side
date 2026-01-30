import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import TidalSearchController from "./controllers/tidal_search_controller"
import VotePointsController from "./controllers/vote_points_controller"
import ToggleController from "./controllers/toggle_controller"
import ScheduleModeController from "./controllers/schedule_mode_controller"

window.Stimulus = Application.start()
window.Stimulus.register("tidal-search", TidalSearchController)
window.Stimulus.register("vote-points", VotePointsController)
window.Stimulus.register("toggle", ToggleController)
window.Stimulus.register("schedule-mode", ScheduleModeController)
