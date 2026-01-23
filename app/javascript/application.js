import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import TidalSubmissionController from "./controllers/tidal_submission_controller"

window.Stimulus = Application.start()
window.Stimulus.register("tidal-submission", TidalSubmissionController)
