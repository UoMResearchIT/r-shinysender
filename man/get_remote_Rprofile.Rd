% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ss_updateRProfile.R
\name{get_remote_Rprofile}
\alias{get_remote_Rprofile}
\title{Get remote .Rprofile}
\usage{
get_remote_Rprofile(session, warnmissing = FALSE)
}
\arguments{
\item{session}{The session to use}

\item{warnmissing}{Whether to warn if there's no remote .Rprofile}
}
\value{
The contents of the remote .Rprofile
}
\description{
Get the remote .Rprofile on the session
}