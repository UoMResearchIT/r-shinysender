

#' Convert the output from an ls command exectuted on the remote
#' server into a vector of directory entries
#'
#' @param inraw A raw string of bytes (typically as output by
#' ssh::ssh_exec_internal()$stdout)
#'
#' @return A list of directory entries
processls <- function(inraw) {

  entries <- rawToChar(inraw)
  entriessplit <- strsplit(entries, "\\n")[[1]]

  return(entriessplit)

}




#' Test if a directory contains files indicating it contains a shiny app
#'
#' Test for the presence of app.R or (server.R and ui.R) in a
#' directory listing
#'
#' Note this doesn't test anything about the validity of the code in the
#' app files - it just checks if they exist
#'
#' @param directoryEntries A character vector containing directory entries;
#' one per element
#'
#' @return TRUE if the directory contains a Shiny app, FALSE otherwise.
isShinyApp <- function(directoryEntries) {
  return("app.R" %in% directoryEntries |
          ("server.R" %in% directoryEntries & "ui.R" %in% directoryEntries)
  )
}
