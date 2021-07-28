#' Connect to a Shiny Server
#'
#' Connect to the Shiny server referred to in the specified
#' configuration in config.yml, using the given user name
#' and keyfile specified
#'
#' @note If keyfile is NULL, we use ssh::ssh_connects() approach to authentication
#' i.e. .ssh/id_rsa, followed by interactive password authentication
#'
#' @param username The user to log onto the server as
#' @param server The remote Shiny server to connect to.  Uses value set in SHINYSENDER_SERVER environment variable by default
#' @param keyfile The path to the user's private keyfile.
#' the active config.  Will warn otherwise.
#
#' @return An ssh connection object
#'
#' @export
ss_connect <- function(username,
                       server = Sys.getenv("SHINYSENDER_SERVER"),
                       keyfile = NULL){

  if(server == "")
    stop("Pass server parameter, or set SHINYSENDER_SERVER environment variable")


  conname = paste0(username, "@", server)

  session = ssh::ssh_connect(conname,
                              keyfile = keyfile)

}


