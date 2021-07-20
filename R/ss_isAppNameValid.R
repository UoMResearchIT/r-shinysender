#' Check if a Shiny app name is valid
#'
#' Check if a Shiny app name is valid
#'
#' Haven't found any documentation on naming rule, so will
#' go strict and say alphanumeric only.
#'
#' Will preserve the case the user provides.
#'
#' @param appName The name of the app
#'
#' @return TRUE if the app name is valid, FALSE otherwise
#'
ss_isAppNameValid <- function(appName) {

  # Check we've got a character vector of length 1,
  # with something in it
  if (class(appName) != "character")
    return(FALSE)
  if(length(appName) != 1)
    return(FALSE)
  if(nchar(appName) < 1)
    return(FALSE)

  # Check what's in it is a valid name
  cleanName <- gsub("[^A-Za-z0-9]", "", appName)

  if(cleanName == appName)
    return(TRUE)
  else
    return(FALSE)

}
