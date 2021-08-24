#' Convert an appname to a path on the remote
#'
#' @param appname a valid shiny app name, or "~" to return home directory
#'
#' @return A path wrt ~
appnameToPath <- function(appname){

  cleanloc <- NULL
  if(appname == "~") {
    cleanloc = "~"
  } else if(ss_isAppNameValid(appname) ){
    cleanloc = paste0("~/ShinyApps/", appname, "")
  } else {
    stop("Invalid application name")
  }

  return(cleanloc)

}


#' Get remote .Rprofile
#'
#' Get the remote .Rprofile on the session
#'
#' @param session The session to use
#' @param appname The location of the .Rprofile file to return. Will return .Rprofile in home directory if not specified
#' @param remotepath The path of the .Rprofile to return.  Exactly one of appname or remotepath must be specified
#' @param warnmissing Whether to warn if there's no remote .Rprofile
#'
#' @return The contents of the remote .Rprofile
get_remote_Rprofile <- function(session,
                                appname = "~",
                                remotepath = NULL,
                                warnmissing = FALSE
                                ){

  if(!(xor(is.null(appname),
             is.null(remotepath)))){
    stop("Must specify appname or remotepath, not both")
  }

  if(!is.null(appname)) {
    # Check we're getting either the home .Rprofile or one for a potentially valid app name
    cleanloc <- appnameToPath(appname)
    # Create full path
    cleanloc <- paste0(cleanloc, "/.Rprofile")
  } else if(!is.null(remotepath)){
    cleanloc <-  paste0(remotepath, "/.Rprofile")
  }
  remotecommand <- paste0("cat ", cleanloc)

  raw_remote.Rprofile <- ssh::ssh_exec_internal(session,
                                                command = remotecommand,
                                                error = FALSE)

  if(warnmissing & raw_remote.Rprofile$status == 1){
    message("No remote .Rprofile found")
  }

  remote.Rprofile <- process_raw(raw_remote.Rprofile$stdout)

  return(remote.Rprofile)

}

#' Send an Rprofile file to the remote server
#'
#' @param session The session to use
#' @param appname The app to send  to send the  .Rprofile to in ~/ShinyApps/
#' @param remotepath A location to send the file to wrt ~.  Exactly one of appname or remotepath must be specified
#' @param Rprofile A vector containing the Rprofile to send
send_Rprofile <- function(session,
                          appname = "~",
                          remotepath = NULL,
                          Rprofile) {

  stopifnot(class(Rprofile) == "character")

  if(!(xor(is.null(appname),
             is.null(remotepath)))){
    stop("Must specify appname or remotepath, not both")
  }


  # We need a rather convoluted way of uploading the modified Rprofile
  # since we can't upload and rename in one go
  # 1. Get a (local) temp file name
  # 2. Get contents of our modified Rprofile into it
  # 3. Upload this to the server
  # 4. Remote: Execute rename command on bare filename to change it to .Rprofile
  # 5. Delete local temp file

  # Create temp file and fill
  localRprofile_path <- tempfile()
  localRprofile <- file(localRprofile_path)
  writeLines(Rprofile, localRprofile)
  close(localRprofile)

  if(!is.null(appname)) {
    remotepath = appnameToPath(appname)
  }

  # Send it to the remote - this goes to the home directory as a temp filename
  ssh::scp_upload(session, localRprofile_path, verbose = FALSE)

  # Rename it on the remote
  bare_Rprofile_name <- basename(localRprofile_path)
  mv_cmd <- paste0("mv ", bare_Rprofile_name, " ",  remotepath,"/.Rprofile")

  cmdout <- ssh::ssh_exec_internal(session, mv_cmd)
  # Abort if cmd failed
  stopifnot(cmdout$status == 0)

  # Tidy up locally
  unlink(localRprofile_path, expand = FALSE)

  # invisible()
}

#' Returns the location of our deployed .Rprofile fragment to install on remote
#' server
#'
#' @return The location of our .Rprofile fragment
ShinySenderRprofilePath <- function() {

  system.file("remoteprofile/shinysender_Rprofile", package = "shinysender",
              mustWork = TRUE)
}

#' Returns the location of our staging .Rprofile fragment to install on remote
#' server
#'
#' @return The location of our .Rprofile fragment
ShinySenderRprofilePathStaging <- function() {

  system.file("remoteprofile/shinysender_staging_Rprofile", package = "shinysender",
              mustWork = TRUE)
}

#' Update a .Rprofile file with the ShinySender code needed to use
#' Packrat with the hosted applications
#'
#' Based on the code used in packrat:::editRprofileAutoloader()
#'
#' Rprofile should be the contents of the .Rprofile file, as a characater
#' vector (one entry per line). This is what you get from ReadLines() if using
#' a local Rprofile, or shinysender:::process_raw() if using the results of a
#' remote ssh command
#'
#' @param Rprofile A character vector containing the Rprofile
#' @param action Whether to update the remote Rprofile with the shinysender
#' fragment, or delete it
#' @param rprofilefragmentpath The path to the fragment to add
#'
#' @return The modified Rprofile, as a character vector
shinysenderize_Rprofile <- function(Rprofile, action = c("update", "delete"),
                                    rprofilefragmentpath = ShinySenderRprofilePath() ) {

  # resolve action argument
  action <- match.arg(action)

  stopifnot(class(Rprofile) == "character")

  ## Read the .Rprofile in and see if it's been packified
  packifyStart <- grep("#### Shinysender Loader ####", Rprofile, fixed = TRUE)

  packifyEnd <- grep("#### Shinysender Loader End ####", Rprofile, fixed = TRUE)

  # Remove any existing fragment
  if (length(packifyStart) && length(packifyEnd))
    Rprofile <- Rprofile[-c(packifyStart:packifyEnd)]

  ## Append our fragment to the original .Rprofile
  if (identical(action, "update"))
    Rprofile <- c(Rprofile, readLines(rprofilefragmentpath))

  return(Rprofile)
}




