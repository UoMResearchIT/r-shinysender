#' List apps installed on a remote server
#'
#' Return a vector containing the apps installed on a Shinyserver
#'
#' @note appdir will probably never need changing - this appears to be
#' hardcoded in the Shiny Server code
#'
#' @param session The ssh session
#' @param appdir The location of the folder containing the user's ShinyApps
#'
#' @return A vector containing the user's apps; NULL if there are none
#'
#' @export
ss_listapps <- function(session,
                        appdir = "~/ShinyApps"){

  # TODO Handle no ShinyApps directory
  # TODO verify appdir is a valid directory name

  listappcmd <- paste0("ls ", appdir)

  out <- ssh::ssh_exec_internal(session, listappcmd)

  shinyapps <- (rawToChar(out$stdout))
  appvect <- strsplit(shinyapps, "\\n")[[1]]

  # TODO Handle log directory
  # TODO check each directory contains a (potentially) valid app
  return(appvect)
}

