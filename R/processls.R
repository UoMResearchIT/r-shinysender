

#' Convert the output from an command executed on the remote
#' server into a vector; one row per line
#'
#' @param inraw A raw string of bytes (typically as output by
#' ssh::ssh_exec_internal()$stdout)
#'
#' @return A vector containing the returned data
process_raw <- function(inraw) {

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
#' @param includeMarkdown Whether to include index.Rmd as a potentially valid app
#'
#' @return TRUE if the directory contains a Shiny app, FALSE otherwise. Return
#' NA if an invalid combination of app files are included
isShinyApp <- function(directoryEntries, includeMarkdown = TRUE) {

  if (includeMarkdown) {
    if ("index.Rmd" %in% directoryEntries) { # Markdown app
      # Excluding this, what's left shouldn't be a shiny app

      whatsleft = isShinyApp(directoryEntries, includeMarkdown = FALSE)

      if (isFALSE(whatsleft))
        return(TRUE)
      else
        return(NA)


    }
  }


  if (all(c("app.R", "server.R", "ui.R") %in% directoryEntries))
    return(NA)

  # Need ui & server or neither
  if (xor("ui.R" %in% directoryEntries,
         "server.R" %in% directoryEntries))
    return(NA)

  if ("app.R" %in% directoryEntries & any(c("ui.R", "server.R") %in% directoryEntries))
    return(NA)

  return("app.R" %in% directoryEntries |
          ("server.R" %in% directoryEntries & "ui.R" %in% directoryEntries)
  )
}


#' Test if a directory contains a packrat directory
#'
#' Test whether an (app) directory contains a packrat directory
#'
#' This function is used to see whether the app (likely) uses packrat to manage
#' package dependencies.
#'
#' @param directoryEntries A character vector containing directory entries;
#' one per element
#'
#' @return TRUE if the directory contains a Packrat app
isPackratApp <- function(directoryEntries) {

  if ("packrat" %in% directoryEntries)
    return(TRUE)
  else
    return(FALSE)

}
