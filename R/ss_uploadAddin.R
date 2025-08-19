#' Upload an app
#'
#' RStudio addin to automatically upload an app
#'
#' @export
ss_uploadAddin <- function() {
  # Check required environment variables for default login set
  checkenv = c(username = "SHINYSENDER_USER", servername = "SHINYSENDER_SERVER")

  errstring <- ""
  for (ci in seq_along(checkenv)) {
    ce = checkenv[ci] # Environment variable
    cn = names(checkenv)[ci] # Example name for environment variable

    if (Sys.getenv(ce) == "") {
      errstring <- paste0(
        errstring,
        "You must set the ",
        ce,
        " environment variable before using the addin.\nUse 'Sys.setenv(",
        ce,
        " = ",
        '"',
        cn,
        '")',
        "'\n"
      )
    }
  }

  if (errstring != "") {
    stop(errstring)
  }

  # Get name for remote app
  appdir <- getwd()
  envRemoteName <- Sys.getenv("SHINYSENDER_REMOTENAME")
  if (envRemoteName != "") {
    remoteName = envRemoteName
  } else {
    remoteName = basename(appdir)
  }

  if (!ss_isAppNameValid(remoteName)) {
    stop(
      remoteName,
      " is not a valid application name.\nUse 'Sys.setenv(",
      'SHINYSENDER_REMOTENAME = "appname") to set a valid name.'
    )
  }

  session <- ss_connect()

  # Setup server (this won't do anything if already setup)
  ss_setupserver(session)

  # Close session when we quit
  on.exit(
    {
      ss_disconnect(session)
    },
    add = TRUE
  )

  ss_uploadappdir(session, appdir, remoteName, overwrite = TRUE)
}
