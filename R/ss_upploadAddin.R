#' Upload an app
#'
#' RStudio addin to automatically upload an app
#'
#' @export
ss_upload_addin <- function() {

  session <- ss_connect()

  appdir <- getwd()

  stopifnot(isShinyApp(list.files(appdir)))


  ss_uploadappdir(session, appdir, basename(appdir), overwrite = TRUE)


}
