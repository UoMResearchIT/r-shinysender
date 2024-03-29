% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ss_listapps.R
\name{ss_listdir}
\alias{ss_listdir}
\title{List apps installed on a remote server}
\usage{
ss_listdir(session, appdir = "~/ShinyApps")
}
\arguments{
\item{session}{The ssh session}

\item{appdir}{The location of the folder containing the user's ShinyApps}
}
\value{
A vector containing the user's apps; NULL if there are none
}
\description{
Return a vector containing the apps installed on a Shinyserver
}
\note{
appdir will probably never need changing - this appears to be
hardcoded in the Shiny Server code
}
