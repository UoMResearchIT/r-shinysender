% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ss_uploadappdir.R
\name{ss_uploadappdir}
\alias{ss_uploadappdir}
\title{Upload an app to the shiny server}
\usage{
ss_uploadappdir(
  session,
  appDir,
  appName,
  ...,
  overwrite = FALSE,
  method = "direct_home"
)
}
\arguments{
\item{session}{The ssh session to use for the upload}

\item{appDir}{The local directory containing the app to upload}

\item{appName}{The name of the application - this will form part of the URL
for the app}

\item{...}{arguments forwarded to `ss_bundleapp`}

\item{overwrite}{Whether to overwrite or abort if the app directory already exists}

\item{method}{The deployment method - see details}
}
\value{
One of "success", "alreadyExists", "otherError"
}
\description{
Upload all the files in the app directory to the Shiny server
}
\details{
method: Only "direct_home" is currently supported.  This uses the ssh
session passed to the function to ssh the bundle file to the user's
~/ShinyApps directory and decompresses it, before removing the bundle file.
In future we could support, e.g. ShinyProxy deployment by creating a Docker
image containing the bundle
}
