#' Launch Shiny Sender's frontend
#'
#' This launches the (optional) frontend for ShinySender
#'
#' All of Shiny Sender's functionality can be accessed via the ss_ functions
#' Sometimes it's nice to do things graphically - this (locally running) Shiny
#' app lets you do this
#'
#' @export
ss_frontend <- function() {
  # Based on https://deanattali.com/2015/04/21/r-package-shiny-app/
  appDir <- system.file("", "frontend", package = "shinysender")
  if (appDir == "") {
    stop("Could not find frontend app in package", call. = FALSE)
  }

  if(requireNamespace("shiny", quietly = TRUE)
     & requireNamespace("shinydashboard", quietly = TRUE))  {
    shiny::runApp(appDir, display.mode = "normal")
  } else {
    stop("Please check the 'shiny' and 'shinydashboard' packages are installed on your machine")
  }
}
