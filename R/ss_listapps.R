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
  # TODO handle files in ~/ShinyApps - show or not?

  listappcmd <- paste0("ls ", appdir)

  out <- ssh::ssh_exec_internal(session, listappcmd)

  appvect <- processls(out$stdout)
  # TODO Handle log directory
  # TODO check each directory contains a (potentially) valid app
  return(appvect)
}


#' Report on the apps installed on the remote server
#'
#' Return a tibble containing details of each directory in the user's app
#' directory:
#'
#' * Is the directory a potentially valid Shiny app (i.e. contains app.R or (ui.R and server.R))
#' * Does it have a packrat directory?
#' * Any logs associated with the app
#'
#' @param session The ssh session
#' @param appdir The location of the folder containing the user's ShinyApps
#'
#' @return A data frame containing details about each entry in the user's app
#' directory
#'
#' @export
ss_appreport <- function(session,
                         appdir = "~/ShinyApps"){


  possibleApps <- ss_listapps(session, appdir)

  appinfo <- list()
  i <- 1
  for(p in possibleApps){

    cmd <- paste0("ls ", appdir, "/", p)
    out <- ssh::ssh_exec_internal(session, cmd)

    # TODO Catch if errors

    shinyApp = isShinyApp(processls(out$stdout))

    thisrow <- c(entryname = p,
                       isApp = shinyApp)


    appinfo[[i]] <- thisrow
    i <- i + 1

  }

  # Make into a data frame
  appout <- as.data.frame(do.call(rbind, appinfo))

  return(appout)
}




