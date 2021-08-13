#' Set up .Rprofile on remote server, and create ~/ShinyApps if it doesn't
#' exist
#'
#' Set up the user's environment with an appropriate .Rprofile to
#' load packrat libraries when running their apps
#'
#' We use Packrat to reproduce the local system's libraries as closely
#' as possible on the Shiny server.  We need a way of making the app
#' aware that it should be using its own local (i.e. Packrat) libraries
#' when running.
#'
#' This function uploads an .Rprofile to the user's home directory
#'
#' @param session The session to upload the .Rprofile to
#'
#' @export
ss_setupserver <- function(session){
  # TODO require user to confirm it's OK to do what we plan to,
  # as we're altering their home directory

  # Create required directories if they doesn't exist
  remotedirs <- c("ShinyApps", "ShinyApps_staging")

  for (rd in remotedirs){
    if ( !does_directory_exist(session, rd) ){
      create_remote_dir(session, rd)
    }
  }


  # TODO check packrat is available to the user
  # If not - install to users local library?? (as optional parameter)
  remote_packrat = ss_is_remote_package_installed(session, package = "packrat")

  if(!remote_packrat) {
    stop("Packrat is not installed on the remote server")
  }

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

#' Check whether a directory exists in user's homedir on the remote machine
#'
#' @param sesison The session to use
#' @param dirname The directory name, relative to ~
does_directory_exist <- function(session ,dirname){

  dirnameslash <- paste0(dirname, "/")

  remoteCmd <- "ls -d */"
  returndata <- ssh::ssh_exec_internal(session, remoteCmd, error = FALSE)

  if(returndata$status == 0) { # Command worked - see what directories we have

    remotedirs <- process_raw(returndata$stdout)
    return(dirnameslash %in% remotedirs)

  } else {
    errstring <-  rawToChar(returndata$stderr)

    if(grepl("ls: cannot access '*/': No such file or directory",
             errstring,
             fixed = TRUE)) {
      # No directories, so no dirname
      return(FALSE)
    } else {
      stop(paste0("Could not determine if ~/", dirname,  "exists on remote:",
           errstring))
    }

  }

}

#' Create a directory on the remote if it doesn't already exist
#'
#' @param session The sesison to use
#' @param dirname The directory name, relative to ~
#'
create_remote_dir <- function(session, dirname){

  alreadyThere <- does_directory_exist(session, dirname)
  if(alreadyThere)
    stop(paste0("~/", dirname, " already exists on remote server"))

  remoteCmd <- paste0("mkdir ", dirname)

  retcode <- ssh::ssh_exec_wait(session, remoteCmd)

  if(retcode != 0)
    stop(paste0("Remote command failed when creating ~/",
    dirname, " directory"))

  # Check the directory exists now we've made it
  if(!does_directory_exist(session, dirname))
    stop(paste0("Remote command apparently worked, but cannot see ~/",
    dirname, " directory"))

}
