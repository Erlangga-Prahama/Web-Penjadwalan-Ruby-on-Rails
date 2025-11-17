// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
import TimeblockController from "./timeblock_controller";

application.register("timeblock", TimeblockController);
eagerLoadControllersFrom("controllers", application);

import SpinnerController from "./spinner_controller";
application.register("spinner", SpinnerController);

import ConfirmGenerateController from "./confirm_generate_controller";
application.register("confirm-generate", ConfirmGenerateController);

import Unavailable from "./unavailable_controller";
application.register("unavailable", Unavailable);

import SubjectSelectorController from "./subject_selector_controller";
application.register("subject-selector", SubjectSelectorController);
