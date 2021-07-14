#' Connect to a Shiny Server
#'
#' Connect to the Shiny server referred to in the specified
#' configuration in config.yml, using the given user name
#' and keyfile specified
#'
#' @param config The configuration name to use from config.yml. This will
#' follow the config package's inheritance rules (i.e. default: must exist
#' in the file, other configs inherit values not explicitly specified)
#' @param username The user to log onto the server as
#' @param keyfile The path to the user's private keyfile
#' @param hostverify If TRUE, abort if the host's expected SHA1 isn't given in
#' the active config.  Will warn otherwise.
#
#' @return An ssh connection object
#'
#' @export
ss_connect <- function(username,
                       keyfile,
                       config = "default",
                       hostverify = TRUE){

  # TODO verify username syntatcially valid

  # TODO verify keyfile exists

  server = config::get("server", config = config)
  if(is.null(server)){
    stop("'server' field not found in config")
  }

  conname = paste0(username, "@", server)

  session = ssh::ssh_connect(conname,
                              keyfile = keyfile,
                             verbose = 2)

  # Verify session matches what we expect
  expectedkey = config::get("serverfingerprint",
                            config = config)

  if(is.null(expectedkey)) {

    # Stop or warn according to how strict we want to be
    if(hostverify)
      errfunc = stop
    else
      errfunc = warning

    errfunc("'servefingerprint' not found in config.  Not performing hostverification")

    return(session)
  } else {
    actualkey = ssh::ssh_info(session)$sha1

    if (expectedkey != actualkey) {
      stop("Expected sha1 key does not match server's key")
    }

    return(session)
  }

  stop("Should never get here")

}


