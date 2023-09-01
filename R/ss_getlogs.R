#' Get error logs for an app from the remote server
#'
#' @param session The ssh session to use
#' @param appName The name of the application to collect logs for.  Defaults to the name of your current local directory
#' @param what One of "last", "list", or a row index as returned by list.  Defaults to "last" - the most recent log for the app
#'
#' @return An invisible copy of the selected logfile, or a visible data frame containing the remote log files for the app
#'
#' @export
ss_getlogs <- function(session,
                       appName = basename(getwd()),
                       what = "last") {

  alllogs <- ss_listdir(session, "~/ShinyApps/log")

  # Parse the filenames into a data frame
  proto <- data.frame(appName = character(),
                      user = character(),
                      date = integer(),
                      time = integer(),
                      pid = integer())
  logdata <- utils::strcapture("(\\w+)-(\\w+)-(\\d+)-(\\d+)-(\\d+)\\.log",
                        alllogs, proto)
  logdata <- cbind( logname = alllogs, logdata )

  logdata$datetime <- as.POSIXlt(paste(logdata$date,
                                       logdata$time),
                                 format = "%Y%m%d %H%M%S")
  logdata$date <- NULL
  logdata$time <- NULL

  applogs <- logdata[logdata$appName == appName,]

  # Sort by date and time
  appsort <- applogs[order(applogs$datetime),]

  if (what == "list") { # data frame of log files for the app
    return(appsort)
  }

  if (is.numeric(what)) { # Return log relating to a row index

    wantfile <- appsort[as.numeric(rownames(appsort)) == what, "logname"]

  } else if (what == "last") { # Return most recent log for app
    # Most recent will be last
    wantfile <- appsort[nrow(appsort), "logname"]
  } else {
    stop("What must be 'last', 'list', or a row number")
  }

  logloc <- paste0("~/ShinyApps/log/", wantfile)

  remotecommand <- paste0("cat ", logloc)

  raw_log <- ssh::ssh_exec_internal(session,
                                    command = remotecommand,
                                    error = FALSE)

  remote.log <- process_raw(raw_log$stdout)

  message(wantfile)
  message()
  message(paste0(remote.log, "\n"))
  invisible(remote.log)

}

