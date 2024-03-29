% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ss_bundleapp.R
\name{ss_bundleapp}
\alias{ss_bundleapp}
\title{Prepare an application bundle}
\usage{
ss_bundleapp(
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
)
}
\arguments{
\item{appDir}{The directory containing the Shiny app. Defaults to current
directory}

\item{appName}{The name to call the app when it is published}

\item{appFiles}{defaults to `rsconnect:::bundleFiles(appDir)`. Consider
providing an explicit list modified from `rsconnect::listBundleFiles`,
or adding a `.rscignore` file with a list of exceptions.}

\item{appPrimaryDoc, appMode, contentCategory, metadata, quarto}{are passed
to `rsconnect:::appMetadata`}

\item{verbose, quiet, pythonConfig, image}{along with the results of
`rsconnect:::appMetadata` are passed to `rsconnect:::bundleApp`}
}
\value{
The location of the created bundle file.
}
\description{
Prepare an application bundle, containing the app code, data and
a manifest.json file with dependencies (taken from `renv`)
}
\details{
*NOTE*: in order to include `packrat` dependencies, make sure to
set `Sys.setenv(RSCONNECT_PACKRAT = TRUE)`

This function is a wrapper around some of the (internal) functionality
of [rsconnect][pkg::rsconnect]
}
