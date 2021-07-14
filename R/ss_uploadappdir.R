#' Upload an app to the shiny server
#'
#' Upload all the files in the app directory to the Shiny server
#'
#' @param session The ssh session to use for the upload
#' @param appdir The local directory containing the app to upload
#' @param appname The name of the application - this will form part of the URL
#' for the app
#'
#' @export
ss_uploadappdir <- function(session, appdir, appname){


  toupload <- list.files(appdir,
                         full.names = TRUE,
                         recursive = TRUE)
  # TODO establish if we need all.files = TRUE (for renv - think this uses
  # a hidden directory

  # TODO check we have a potentially valid Shiny app (i.e. ui.R+server.R or app.R)
  # at top level


  # TODO heck app name
  # Make remote directory
  remote = paste0("ShinyApps/", appname)


  ssh::ssh_exec_internal(session, paste0("mkdir ~/", remote))
  # TODO - decide how to handle if already exists

  # Upload files
  ssh::scp_upload(session,
                  file = toupload,
                  to = paste0("./", remote))


  return("success")
}


