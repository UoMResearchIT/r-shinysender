#' Upload an app
#'
#' RStudio addin to automatically upload an app
#'
#' @export
ss_upload_addin <- function() {

  # Check required envionment variables for default login set
  checkenv = c("SHINYSENDER_USER", "SHINYSENDER_SERVER")
  for (ce in checkenv) {

    if(Sys.getenv(ce) == ""){
      stop("You must set the ", ce,  " environment variable before using the addin")
    }

  }

  session <- ss_connect()

  appdir <- getwd()

  stopifnot(isShinyApp(list.files(appdir)))

  # TODO let user set addin app name via environment variable
  ss_uploadappdir(session, appdir, basename(appdir), overwrite = TRUE)


}
