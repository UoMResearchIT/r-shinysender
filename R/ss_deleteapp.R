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

  # Check application name is valid
  stopifnot(shinysender:::ss_isAppNameValid(appName))

  # Only deal with a single application at a time
  # TODO - handle >1 app per function call
  stopifnot(length(appName) == 1)

  # Check app is in directory
  installedApps <- ss_listapps(session)
  stopifnot(appName %in% installedApps)

  appPath = paste0("~/ShinyApps/", appName)

  remotecommand = paste0("rm -rf ", appPath)

  if (prompt){
    print(remotecommand)
    prompt <- utils::askYesNo("Run command?")

    stopifnot(prompt==TRUE)

  }

  retval <- ssh::ssh_exec_wait(session, remotecommand)
}

