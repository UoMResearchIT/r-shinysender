#' Delete a deployed app
#'
#' Delete an app that's been deployed
#'
#' @param session The session to connect to
#' @param appName The name of the app to delete
#' @param prompt Show remote command that will be run before deleting
#'
#' @export
ss_deleteapp <- function(session, appName, prompt = TRUE){

  # Only deal with a single application at a time
  # TODO - handle >1 app per function call
  stopifnot(length(appName) == 1)

  # Check application name is valid
  stopifnot(ss_isAppNameValid(appName))

  # Check app is in directory
  installedApps <- ss_listdir(session)
  if(!appName %in% installedApps) {
    stop("App not installed on remote server")
  }

  appPath = paste0("~/ShinyApps/", appName)

  remotecommand = paste0("rm -rf ", appPath)

  if (prompt){
    print("Run remote command?")
    print(remotecommand)
    proceed <- utils::askYesNo("Run command?")

    if(proceed != TRUE){
      stop("Not deleting remote app")
    }

  }

  retval <- ssh::ssh_exec_wait(session, remotecommand)

  return(retval)
}

