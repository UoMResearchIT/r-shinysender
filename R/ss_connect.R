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
                       keyfile = NULL) {

  errstring <- ""
  if (server == "")
    errstring <- paste0(errstring,
                        "Pass server parameter, or set SHINYSENDER_SERVER environment variable\n")

  if (username == "")
    errstring <- paste0(errstring,
                        "Pass username parameter.  USERNAME environment variable was not set\n")

  if (errstring != "")
    stop(errstring)

  conname = paste0(username, "@", server)

  session = ssh::ssh_connect(conname,
                              keyfile = keyfile)

  return(session)
}

#' Get the login of the logged on user
#'
#' Return the login of the user to logon with.  This is usually current user.
#'
#' We can override the login by setting the SHINYSENDER_USER environment variable
#'
#' The current user's login is stored in the USER and/or USERNAME environment variables
#' Which are populated seems to depend on the platform.  This function attempts
#' to get the username robustly regardless of platform
#'
#' USER  USERNAME  Platform
#' Y    Y         Linux
#' Y    N         Mac
#' N    Y         Windows
#'
#' @return The user name
getUserName <- function() {

  # Use the username set in SHINYSENDER_USER in preference to
  # anything else
  shinyuser <- Sys.getenv("SHINYSENDER_USER")

  if (shinyuser != "") {
    # Check if user specified username is a valid login name
    # regex taken from NAME_REGEX default in man adduser.conf
    # Should we be testing USER/USERNAME against this too?
    # Presumably user could change these if so inclined...
    if (!grepl("^[a-z][-a-z0-9]*$", shinyuser)) {
      stop("Invalid username specified in SHINYSENDER_USER")
    }

    return(shinyuser)
  }

  user <- Sys.getenv("USER")
  username <- Sys.getenv("USERNAME")

  if (user == "" & username == "") {
    stop("Could not determine username")
  }

  # Both match - probably linux
  if (user == username) {
    return(user)
  }

  if (nchar(user) > 0 & nchar(username) == 0 )
    return(user)
  else if (nchar(username) > 0 & nchar(user) == 0 )
    return(username)
  else
    stop("user and username variables both set, but not equal")

  stop("Error getting username")
}
