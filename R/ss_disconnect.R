#' Disconnect from Shiny server
#'
#' Disconnect a session from the Shiny server
#'
#' @param session The session to disconnect
#'
#' @export
ss_disconnect <- function(session) {
  ssh::ssh_disconnect(session)
}
