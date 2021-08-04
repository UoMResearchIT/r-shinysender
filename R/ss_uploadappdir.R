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


    if (tolower(appName) %in% tolower(installedApps) ) {
      message(appName, " is already on the server")
      if (!overwrite) {
        return("alreadyExists")
      } else {
        message("Deleting existing app and re-uploading")
        ss_deleteapp(session, appName, prompt = FALSE)
      }
    }

    message("Uploading application bundle")
    tryCatch(
      ssh::scp_upload(session,
                      file = bundleFile,
                      to = "./ShinyApps"),
      error = function(c) stop("Upload failed")
    )

    # Make remote directory and decompress
    remotecommand <- paste0("cd ~/ShinyApps && mkdir ",
                            appName,
                            " && tar xzf ",
                            bundleBareFile,
                            " -C ",
                            appName,
                            " && rm ",
                            bundleBareFile)

    message("Decompressing bundle on remote machine")
    retval = ssh::ssh_exec_wait(session, remotecommand)

    if (retval != 0){
      warning("App decompression failed")
      return("otherError")
    }

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
    remotecommand <- paste0("cd ./ShinyApps/", appName,
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





}

