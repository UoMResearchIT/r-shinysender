#' Prepare an application bundle
#'
#' Prepare an application bundle, containing the app code, data and
#' a manifest.json file with dependencies (taken from `renv`)
#'
#' *NOTE*: in order to include `packrat` dependencies, make sure to
#' set `Sys.setenv(RSCONNECT_PACKRAT = TRUE)`
#'
#' This function is a wrapper around some of the (internal) functionality
#' of [rsconnect][pkg::rsconnect]
#'
#' @param appDir The directory containing the Shiny app. Defaults to current
#' directory
#' @param appName The name to call the app when it is published
#' @param appFiles defaults to `rsconnect:::bundleFiles(appDir)`. Consider
#' providing an explicit list modified from `rsconnect::listBundleFiles`,
#' or adding a `.rscignore` file with a list of exceptions.
#' @param appPrimaryDoc,appMode,contentCategory,metadata,quarto are passed
#' to `rsconnect:::appMetadata`
#' @param verbose,quiet,pythonConfig,image along with the results of
#' `rsconnect:::appMetadata` are passed to `rsconnect:::bundleApp`
#'
#' @return The location of the created bundle file.
#'
#' @export
ss_bundleapp <- function(
  appDir = getwd(),
  appName,
  appFiles = NULL,
  appPrimaryDoc = NULL,
  appMode = NULL,
  contentCategory = NULL,
  metadata = list(),
  verbose = FALSE,
  quiet = FALSE,
  quarto = NA,
  pythonConfig = NULL,
  image = NULL
) {
  # Check app name is OK
  stopifnot(ss_isAppNameValid(appName))

  # Check we've got something that looks like a shiny app in the directory
  direntries <- list.files(path = appDir)
  if (!isShinyApp(direntries)) {
    stop(appDir, " does not appear to contain a Shiny app")
  }

  # Extract functions we need from rsconnect package
  # This avoids a note in the cran checks, since they're internal
  # It's a bit of a hack, based on
  # https://stat.ethz.ch/pipermail/r-devel/2013-August/067210.html
  rscBundleApp <- get("bundleApp", envir = asNamespace("rsconnect"))
  rscAppMetadata <- get("appMetadata", envir = asNamespace("rsconnect"))

  if (is.null(appFiles)) {
    rscBundleFiles <- get("bundleFiles", envir = asNamespace("rsconnect"))
    appFiles = rscBundleFiles(appDir)
  }

  appMetadata <- rscAppMetadata(
    appDir = appDir,
    appFiles = appFiles,
    appPrimaryDoc = appPrimaryDoc,
    quarto = quarto,
    appMode = appMode,
    contentCategory = contentCategory,
    isShinyappsServer = FALSE,
    metadata = metadata
  )

  bundlePath <- rscBundleApp(
    appName = appName,
    appDir = appDir,
    appFiles = appFiles,
    appMetadata = appMetadata,
    quiet = quiet,
    verbose = verbose,
    pythonConfig = pythonConfig,
    image = image
  )

  return(bundlePath)
}
