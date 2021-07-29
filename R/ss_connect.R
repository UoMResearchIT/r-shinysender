#' Connect to a Shiny Server
#'
#' Connect to the Shiny server referred to in the specified
#' configuration in config.yml, using the given user name
#' and keyfile specified
#'
#' @note If keyfile is NULL, we use ssh::ssh_connects() approach to authentication
#' i.e. .ssh/id_rsa, followed by interactive password authentication
#'
#' @param username The user to log onto the server as. Defaults to current user
#' @param server The remote Shiny server to connect to.  Uses value set in SHINYSENDER_SERVER environment variable by default
#' @param keyfile The path to the user's private keyfile.
#' the active config.  Will warn otherwise.
#
#' @return An ssh connection object
#'
#' @export
ss_connect <- function(username = getUserName(),
                       server = Sys.getenv("SHINYSENDER_SERVER"),
                       keyfile = NULL){

  if(server == "")
    stop("Pass server parameter, or set SHINYSENDER_SERVER environment variable")

  if(username == "")
    stop("Pass username parameter.  USERNAME environment variable was not set")

  conname = paste0(username, "@", server)

  session = ssh::ssh_connect(conname,
                              keyfile = keyfile)

  return(session)
}

#' Get the login of the logged on user
#'
#' Return the login of the current user.
#'
#' The username is stored in the USER and/or USERNAME environment variables
#' Which are populated seems to depend on the platform.  This function attempts
#' to get the username robustly regardless of platform
#'
#' USER  USERNAME  Platform
#' Y    Y         Linux
#' Y    N         Mac
#' N    Y         Windows
#'
#' @return The user name
getUserName <- function(){

  user <- Sys.getenv("USER")
  username <- Sys.getenv("USERNAME")

  if (user == "" & username == "") {
    stop("Could not determine username")
  }

  # Both match - probably linux
  if(user == username) {
    return(user)
  }

  if(nchar(user) > 0 & nchar(username) == 0 )
    return(user)
  else if(nchar(username) > 0 & nchar(user) == 0 )
    return(username)
  else
    stop("user and username variables both set, but not equal")

  stop("Error getting username")
}
