# Figure out what libraries we need to install on Shiny server
# Using packages on PC image 2122 as starting point



library(tidyverse)
library(httr)
library(jsonlite)
# devtools::install_github("r-hub/sysreqs") (not on CRAN)
library(sysreqs)

# Load in the list of packages from existing machine
# write.csv(installed.packages(), "outfile.csv" )
pclibs <- read_csv("installed2122.csv")



installedlibs <- pclibs$Package

wantdebs <- NULL
for (thislib in installedlibs) {
  message(thislib)
  getstring <- paste0("https://sysreqs.r-hub.io/pkg/", thislib)
  result <- httr::GET(getstring)
  flatresult <- unlist(content(result, flatten = TRUE))
  # Fairly horrid way of getting all the DEB names out
  if (!is.null(flatresult))
    wantdebs <- c(wantdebs, flatresult[str_detect(names(flatresult), "DEB")])
}

#Make them unique

uniquedebs <- unique(wantdebs)

paste("apt-get install", paste(uniquedebs, collapse = " "))
