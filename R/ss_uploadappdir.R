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
#' @param method The deployment method - see details
#'
#' @export
ss_uploadappdir <- function(session, appDir, appName,
                            method = "direct_home"){

  # TODO check we have a potentially valid Shiny app (i.e. ui.R+server.R or app.R)
  # at top level

  bundleFile <- ss_bundleapp(appDir = appDir,
                             appName = appName)


  if (method == "direct_home") {
    # TODO check ~/ShinyApps exists

    ssh::scp_upload(session,
                    file = bundleFile,
                    to = "./ShinyApps")
    # Make remote directory

    # TODO - decide how to handle if already exists
    # remote = paste0("ShinyApps/", appName)
    #
    #
    # ssh::ssh_exec_internal(session, paste0("mkdir ~/", remote))

  } else {
    stop("Only direct upload currently supported")
  }





}


