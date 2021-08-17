#' Upload an app to the shiny server
#'
#' Upload all the files in the app directory to the Shiny server
#'
#' @details method: Only "direct_home" is currently supported.  This uses the ssh
#' session passed to the function to ssh the bundle file to the user's
#' ~/ShinyApps directory and decompresses it, before removing the bundle file.
#' In future we could support, e.g. ShinyProxy deployment by creating a Docker
#' image containing the bundle
#'
#' @param session The ssh session to use for the upload
#' @param appDir The local directory containing the app to upload
#' @param appName The name of the application - this will form part of the URL
#' for the app
#' @param overwrite Whether to overwrite or abort if the app directory already exists
#' @param method The deployment method - see details
#'
#'
#' @return One of "success", "alreadyExists", "otherError"
#'
#' @export
ss_uploadappdir <- function(session, appDir, appName,
                            overwrite = FALSE,
                            method = "direct_home"){

  # TODO check we have a potentially valid Shiny app (i.e. ui.R+server.R or app.R)
  # at top level


  if(!ss_isAppNameValid(appName)) {
    stop(appName, " is not a valid Shiny app name")
  }

  message("Preparing application bundle")
  bundleFile <- ss_bundleapp(appDir = appDir,
                             appName = appName)
  bundleBareFile <- basename(bundleFile)

  # Check bundleBareFile has expected format since we use it in
  # shell commands
  if(gsub("rsconnect-bundle[^[:alnum:]]\\.tar\\.gz", "", bundleBareFile) != bundleBareFile){
    stop("Error with bundle filename:", bundleBareFile)
  }

  if (method == "direct_home") {
    # Check required directories exist
    required_dirs <- c("ShinyApps", "ShinyApps_staging")
    for(rd in required_dirs) {
      if (!does_directory_exist(session, rd) ){
        warning(paste0("~/", rd, " does not exist"))
        return("otherError")
      }
    }


    installedApps <- ss_listdir(session)

    appExistsOnRemote <- tolower(appName) %in% tolower(installedApps)
    if (appExistsOnRemote) {
      message(appName, " is already on the server")
      if (!overwrite) {
        return("alreadyExists")
      }
      # else {
      #   message("Deleting existing app and re-uploading")
      #   ss_deleteapp(session, appName, prompt = FALSE)
      # }
    }

    message("Uploading application bundle")
    tryCatch(
      ssh::scp_upload(session,
                      file = bundleFile,
                      to = "./ShinyApps_staging"),
      error = function(c) stop("Upload failed")
    )

    # Append a random string to the appname to use for staging
    appNameStaging <- paste0(appName, tempBare())


    # Now the file is on the remote, we want it to be cleaned up when we exit
    # the function.  We do this via on.exit so that it will still happen
    # even if the decompression fails
    on.exit({
      remotecommand <- paste0('rm ~/ShinyApps_staging/"', bundleBareFile, '"')
      # print(remotecommand)
      ssh::ssh_exec_wait(session, remotecommand )


      # We move the app from staging, but if this fails (or library restoration
      # fails), we'll need to clean up the staging directory.  Since it most
      # likely doesn't exist (since it's moved), we check whether it's there
      # before deleting
      stagingDir <- paste0("~/ShinyApps_staging/", appNameStaging)

      # Test if stagingDir exists and remove if it does
      remotecommand <- paste0("bash -c '[ -d ", stagingDir,
                              " ] && rm -r ", stagingDir, "'")
      # print(remotecommand)
      ssh::ssh_exec_wait(session, remotecommand )

    }, add = TRUE)

    # Make remote directory and decompress
    remotecommand <- paste0("cd ~/ShinyApps_staging && mkdir ",
                            appNameStaging,
                            " && tar xzf ",
                            bundleBareFile,
                            " -C ",
                            appNameStaging)

    message("Decompressing bundle on remote machine")
    retval = ssh::ssh_exec_wait(session, remotecommand)

    if (retval != 0){
      warning("App decompression failed")
      return("otherError")
    }


    # Setup the app's .Rprofile
    message("Setting up package environment")
    ss_setupRprofile(session,
                     remotepath = paste0("ShinyApps_staging/", appNameStaging))
#
    # Restore the packrat libraries

    # If there are Private github remotes, we'll need to pass the
    # GITHUB_PAT environment variable over
    github_pat = Sys.getenv("GITHUB_PAT")

    # Prepare code to insert set the environment variable
    github_pat_insert = ""
    if(github_pat != "")
      github_pat_insert = paste0('Sys.setenv(GITHUB_PAT="',
                                 github_pat, '");')



    # Project parameter doesn't seem to work, so cd to project directory
    # first
    remotecommand <- paste0("cd ./ShinyApps_staging/", appNameStaging,
                            " && Rscript -e '",
                            github_pat_insert,
                            "packrat::restore()'")

    message("Installing packages on remote machine")
    message("(This may take some time for a new application)")
    retval = ssh::ssh_exec_wait(session, remotecommand )
    if (retval != 0){
      warning("Library restoration on remote server failed")
      return("otherError")
    }

  } else {
    stop("Only direct upload currently supported")
  }


  # If we get here we've uploaded it to staging OK
  # So delete the old app
  if(appExistsOnRemote) {

    message("Removing existing version of app")
    ss_deleteapp(session, appName, prompt = FALSE)

  }

  message("Deploying app from staging location")
  remotecommand <- paste0("mv ~/ShinyApps_staging/", appNameStaging, " ",
                          "~/ShinyApps/", appName)
  retval = ssh::ssh_exec_wait(session, remotecommand )
  if (retval != 0){
    warning("Moving app from staging failed")
    return("otherError")
  }

  message("App deployed to:", appName)






}


#' Return a string suitable for use as a temporary
#' filelestem
#'
#' This is used for the staging directory of an app when we upload
#' one that already exists.
#'
#'
tempBare <- function(){

  # We can't generate a bare filename (i.e. no path info at all)
  # with tempfile()

  # So we generate with and remove everything that's not alphanumeric
  tempfilepath <- tempfile(tmpdir = "/")

  tempbare <- gsub("[^[:alnum:]]", "", tempfilepath)

  return(tempbare)
}
