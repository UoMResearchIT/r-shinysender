#' Check if a Shiny app name is valid
#'
#' Valid names are alphanumeric [underscores and hyphens allowed],
#' between 4 and 63 characters long. Case is preserved.
#' https://github.com/rstudio/rsconnect/issues/142#issuecomment-261393707
#'
#' @param appName The name of the app
#' @return TRUE if the app name is valid, FALSE otherwise
#'
ss_isAppNameValid <- function(appName) {

  if (!isa(appName, "character") || length(appName) != 1)
    return(FALSE)

  grepl("^[A-Za-z0-9_-]{4,63}$", appName)
}
