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

  # TODO use separate staging directory so partially deployed apps aren't visible
  # e.g. ~/ShinyApps_staging


  message("Preparing application bundle")
  bundleFile <- ss_bundleapp(appDir = appDir,
                             appName = appName)
  bundleBareFile <- basename(bundleFile)

  if (method == "direct_home") {
    # Check ~/ShinyApps exists
    if (!ss_does_shinyapps_exist(session) ){
      warning("~/ShinyApps does not exist")
      return("otherError")
    }


    installedApps <- ss_listapps(session)

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
                      to = "./ShinyApps"),
      error = function(c) stop("Upload failed")
    )

    # Append a random string to the appname to use for staging
    appNameStaging <- paste0(appName, tempBare())

    # Make remote directory and decompress
    remotecommand <- paste0("cd ~/ShinyApps && mkdir ",
                            appNameStaging,
                            " && tar xzf ",
                            bundleBareFile,
                            " -C ",
                            appNameStaging,
                            " && rm ",
                            bundleBareFile)

    message("Decompressing bundle on remote machine")
    retval = ssh::ssh_exec_wait(session, remotecommand)

    if (retval != 0){
      warning("App decompression failed")
      return("otherError")
    }


    # Setup the app's .Rprofile
    message("Setting up package environment")
    ss_setupRprofile(session, appNameStaging)

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
    remotecommand <- paste0("cd ./ShinyApps/", appNameStaging,
                            " && Rscript -e '",
                            github_pat_insert,
                            "packrat::restore()'")

    message("Installing packages on remote machine")
    # TODO check if we have a populated packrat cache and only print
    # the following if we don't
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
  remotecommand <- paste0("mv ~/ShinyApps/", appNameStaging, " ",
                          "~/ShinyApps/", appName)
  retval = ssh::ssh_exec_wait(session, remotecommand )
  if (retval != 0){
    warning("Moving app from staging failed")
    return("otherError")
  }

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
