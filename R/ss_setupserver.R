#' Set up .Rprofile on remote server
#'
#' Set up the user's environment with an appropriate .RProfile to
#' load packrat libraries when running their apps
#'
#' We use Packrat to reproduce the local system's libraries as closely
#' as possible on the Shiny server.  We need a way of making the app
#' aware that it should be using its own local (i.e. Packrat) libraries
#' when running.
#'
#' This function uploads an .Rprofile to the user's home directory
#'
#' @param session The session to upload the .RProfile to
#'
#' @export
ss_setupserver <- function(session){
  # TODO require user to confirm it's OK to do what we plan to,
  # as we're altering their home directory

  # TODO check packrat is available to the user
  # If not - install to users local library?? (as optional parameter)
  remote_packrat = ss_is_remote_package_installed(session, package = "packrat")

  if(!remote_packrat) {
    stop("Packrat is not installed on the remote server")
  }




  # TODO append to file rather than overwrite (packrat does this for its autoloader)

  rprofile_file = system.file("remoteprofile/.Rprofile", package = "shinysender",
                              mustWork = TRUE)

  ssh::scp_upload(session,
                  rprofile_file)



}


#' Check whether a package on the remote server is installed
#'
#' @param session The session to use
#' @param package The package to test for
#'
#' @return TRUE if installed, FALSE otherwise
#'
ss_is_remote_package_installed <- function(session, package){

  remoteR <- paste0("if( '", package, "' %in% installed.packages()) { quit(status = 0) } else { quit(status = 1) }")
  remoteRRun <- paste0('Rscript -e "', remoteR, '"')

  retcode <- ssh::ssh_exec_wait(session, remoteRRun)

  if(retcode == 0){
    return(TRUE)
  } else {
    return(FALSE)
  }

}

#' Check whether we have a ~/ShinyApps directory on the remote account
#'
#' Check whether the ~/ShinyApps directory exists
#'
#' @param session The session to use
ss_does_shinyapps_exist <- function(session){

  remoteCmd <- "ls -d */"
  returndata <- ssh::ssh_exec_internal(session, remoteCmd)

  remotedirs <- processls(returndata$stdout)

  return("ShinyApps/" %in% remotedirs)


}


#' Create ~/ShinyApps on remote account
#'
#' @param session The session to use
ss_create_shinyapps <- function(session) {

  alreadyThere <- ss_does_shinyapps_exist(session)
  if(alreadyThere)
    stop("~/ShinyApps already exists on remote server")

  remoteCmd <- "mkdir ShinyApps"

  retcode <- ssh::ssh_exec_wait(session, remoteCmd)

  if(retcode != 0)
    stop("Remote command failed when creating ~/ShinyApps directory")

  # Check the directory exists now we've made it
  if(!ss_does_shinyapps_exist(session))
    stop("Remote command apparently worked, but cannot see ~/ShinyApps directory")
}
