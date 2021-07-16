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

  # TODO append to file rather than overwrite

  rprofile_file = system.file("remoteprofile/.Rprofile", package = "shinysender",
                              mustWork = TRUE)

  ssh::scp_upload(session,
                  rprofile_file)



}
