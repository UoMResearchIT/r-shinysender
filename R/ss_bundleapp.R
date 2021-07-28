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

  # Check app name is OK
  stopifnot(ss_isAppNameValid(appName))

  # Extract functions we need from rsconnect package
  # This avoids a note in the cran checks, since they're internal
  # It's a bit of a hack, based on
  # https://stat.ethz.ch/pipermail/r-devel/2013-August/067210.html
  rscBundleApp <- get("bundleApp", envir = asNamespace("rsconnect"))
  rscBundleFiles <- get("bundleFiles", envir = asNamespace("rsconnect"))


  bundleFile <- rscBundleApp(appName,
                        appFiles = rscBundleFiles(appDir),
                        appPrimaryDoc = NULL, # Unsure what this is used for
                        appDir = appDir,
                        assetTypeName = "application",
                        contentCategory = NULL) # Unsure what this is used for

  return(bundleFile)

}

