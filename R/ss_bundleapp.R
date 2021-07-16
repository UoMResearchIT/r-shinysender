#' Prepare an application bundle
#'
#' Prepare an application bundle, containing the app code, data and
#' package dependencies in packrat form
#'
#' This function is a wrapper around some of the (internal) functionality
#' of [rsconnect][pkg::rsconnect]
#'
#' @param appDir The directory containing the Shiny app. Defaults to current
#' directory
#' @param appName The name to call the app when it is published
#'
#' @return The location of the created bundle file.
#'
#' @export
ss_bundleapp <- function(appDir = ".",
                         appName){

  # TODO test valid app name (low priority?  Not sure why we need to set it
  # this early - that will be at the deployment stage?)


  # TODO figure out away to avoid Cran check note for use of ::: see ?`:::`
  bundleFile <- rsconnect:::bundleApp(appName,
                        appFiles = rsconnect:::bundleFiles(appDir),
                        appPrimaryDoc = NULL, # Unsure what this is used for
                        appDir = appDir,
                        assetTypeName = "application",
                        contentCategory = NULL) # Unsure what this is used for

  return(bundleFile)

}

