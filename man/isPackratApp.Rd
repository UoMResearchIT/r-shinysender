% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/processls.R
\name{isPackratApp}
\alias{isPackratApp}
\title{Test if a directory contains a packrat directory}
\usage{
isPackratApp(directoryEntries)
}
\arguments{
\item{directoryEntries}{A character vector containing directory entries;
one per element}
}
\value{
TRUE if the directory contains a Packrat app
}
\description{
Test whether an (app) directory contains a packrat directory
}
\details{
This function is used to see whether the app (likely) uses packrat to manage
package dependencies.
}
