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
#' @param ... arguments forwarded to `ss_bundleapp`
#'
#' @return One of "success", "alreadyExists", "otherError"
#'
#' @export
ss_uploadappdir <- function(session, appDir, appName,
                            ...,
                            overwrite = FALSE,
                            method = "direct_home") {

  if (!ss_isAppNameValid(appName)) {
    stop(appName, " is not a valid Shiny app name")
  }

  message("Preparing application bundle")
  bundleFile <- ss_bundleapp(appDir = appDir,
                             appName = appName, ...)
  bundleBareFile <- basename(bundleFile)

  # Check bundleBareFile has expected format since we use it in
  # shell commands
  if (gsub("rsconnect-bundle[^[:alnum:]]\\.tar\\.gz", "", bundleBareFile) != bundleBareFile) {
    stop("Error with bundle filename:", bundleBareFile)
  }

  if (method == "direct_home") {
    # Check required directories exist
    required_dirs <- c("ShinyApps", "ShinyApps_staging")
    for (rd in required_dirs) {
      if (!does_directory_exist(session, rd) ) {
        warning(paste0("~/", rd, " does not exist. Run ss_setupserver() to create"))
        return("otherError")
      }
    }

    installedApps <- ss_listdir(session)

    # Note this is case sensitive, since Shiny server is
    appExistsOnRemote <- appName %in% installedApps
    if (appExistsOnRemote) {
      message(appName, " is already on the server")
      if (!overwrite) {
        return("alreadyExists")
      }
      # App will be overwritten if it stages successfully
    }

    # We probably don't want multiple apps differing only in case,
    # so warn if the user has done this.
    casecheck  <- tolower(appName) %in% tolower(installedApps)
    if (!appExistsOnRemote & casecheck) {
      casedups <- installedApps[tolower(appName) == tolower(installedApps)]
      warning(paste("An app with the same name but different case exists on the server. You may wish to delete these using ss_deleteapp():",
                    casedups))
    }

    message("Uploading application bundle")
    tryCatch(
      ssh::scp_upload(session,
                      files = bundleFile,
                      to = "./ShinyApps_staging",
                      verbose = FALSE),
      error = function(c) stop("Upload failed")
    )

    # Append a random string to the appname to use for staging
    appNameStaging <- paste0(appName, tempBare())


    # Now the file is on the remote, we want it to be cleaned up when we exit
    # the function.  We do this via on.exit so that it will still happen
    # even if the decompression fails
    on.exit({
      remotecommand <- paste0('rm ~/ShinyApps_staging/"', bundleBareFile, '"')
      ssh::ssh_exec_wait(session, remotecommand )

      # We move the app from staging, but if this fails (or library restoration
      # fails), we'll need to clean up the staging directory.  Since it most
      # likely doesn't exist (since it's moved), we check whether it's there
      # before deleting
      stagingDir <- paste0("~/ShinyApps_staging/", appNameStaging)

      # Test if stagingDir exists and remove if it does
      remotecommand <- paste0("bash -c '[ -d ", stagingDir,
                              " ] && rm -r ", stagingDir, "'")
      # print(remotecommand)
      ssh::ssh_exec_wait(session, remotecommand )

    }, add = TRUE)

    # Make remote directory and decompress
    remotecommand <- paste0("cd ~/ShinyApps_staging && mkdir ",
                            appNameStaging,
                            " && tar xzf ",
                            bundleBareFile,
                            " -C ",
                            appNameStaging)

    message("Decompressing bundle on remote machine")
    retval = ssh::ssh_exec_wait(session, remotecommand)

    if (retval != 0) {
      warning("App decompression failed")
      return("otherError")
    }


    # Setup the app's .Rprofile
    message("Setting up staging environment")


    # Setup any web proxy needed for staging

    # Path to the file containing the lines we need to add to the
    # remote .Rprofile for staging
    staging_rprofile_path = ShinySenderRprofilePathStaging()
    # Read the default staging .Rprofile in
    our_profile <- readLines(staging_rprofile_path)

    # Setup proxy

    modified_profile <- prepareRprofile(our_profile)

    # tempfile to put the staging profile in
    temp_profile_path <- tempfile()
    writeLines(modified_profile, temp_profile_path)

    ss_setupRprofile(session,
                     remotepath = paste0("ShinyApps_staging/", appNameStaging),
                     rprofilefragmentpath = temp_profile_path)

    # Remove temporary path
    unlink(temp_profile_path, expand = FALSE)

# Restore Libraries ----------------------------------------------------------
# Uses `renv_lockfile_from_manifest` to generate a lockfile object
# from manifest.json, and passing it to renv::restore

    # If there are Private github remotes, we'll need to pass the
    # GITHUB_PAT environment variable over
    tryCatch({
      Sys.setenv(GITHUB_PAT = gitcreds::gitcreds_get(use_cache = FALSE)$password)
    }, error = function(e) {
      warning("Failed to retrieve GIT credentials, try gitcreds::gitcreds_set()")
    })
    github_pat = Sys.getenv("GITHUB_PAT")

    # Check if token has (almost expired) if we have one
    if (github_pat != "")
      check_pat_expiry(pat = github_pat)

    # Prepare code to insert set the environment variable
    # Note that we don't put the PAT in the staging .Rprofile, to
    # avoid the risk of it being saved on the remote
    # Instead we turn off bash history, and set it on the command line
    # for the app deployment.
    github_pat_insert = ""
    if (github_pat != "")
      github_pat_insert = paste0('Sys.setenv(GITHUB_PAT="', github_pat, '"); ')

    # Project parameter doesn't seem to work, so cd to project directory first
    # Turn off history for this since we don't want the PAT to be saved anywhere
    remotecommand <- paste0(
      "set +o history && cd ./ShinyApps_staging/", appNameStaging,
      " && Rscript -e '", github_pat_insert,
      " options(renv.verbose = FALSE);",
      " lockfile <- renv:::renv_lockfile_from_manifest(\"manifest.json\");",
      " lockfile$R$Version <- as.character(lockfile$R$Version);", # see https://github.com/rstudio/renv/issues/1667
      " renv::lockfile_write(lockfile);",
      " renv::activate()'",
      " && Rscript -e '", github_pat_insert,"renv::restore(); renv::status()'")

    message("Installing packages on remote machine")
    message("(This may take some time for a new application)")
    retval = ssh::ssh_exec_wait(session, remotecommand )
    if (retval != 0) {
      warning("Library restoration on remote server failed")
      return("otherError")
    }

  } else {
    stop("Only direct upload currently supported")
  }

  # Replace the staging .Rprofile with the deployment one
  message("Setting up deployment environment")
  ss_setupRprofile(session,
                   remotepath = paste0("ShinyApps_staging/", appNameStaging),
                   rprofilefragmentpath = ShinySenderRprofilePath())

  # If we get here we've uploaded it to staging OK
  # So delete the old app
  if (appExistsOnRemote) {

    message("Removing existing version of app")
    ss_deleteapp(session, appName, prompt = FALSE)

  }

  message("Deploying app from staging location")
  remotecommand <- paste0("mv ~/ShinyApps_staging/", appNameStaging, " ",
                          "~/ShinyApps/", appName)
  retval = ssh::ssh_exec_wait(session, remotecommand )
  if (retval != 0) {
    warning("Moving app from staging failed")
    return("otherError")
  }

  message("App deployed to: ", appName)

  # Derive deployed app URL
  # TODO This assumes we always deploy to host/user/appname
  # which is set on the remote in the server config.

  sessionInfo <- ssh::ssh_session_info(session)

  sessionUser <- sessionInfo$user
  sessionServer <- sessionInfo$host

  if (!is.null(sessionUser) & !is.null(sessionServer)) {
    remoteURL <- paste0("https://", sessionServer, "/",
                        sessionUser, "/", appName)
    message("App deployed to:")
    message(remoteURL)
  }


}

#' Return a string suitable for use as a temporary
#' filesystem
#'
#' This is used for the staging directory of an app when we upload
#' one that already exists.
#'
#'
tempBare <- function() {

  # We can't generate a bare filename (i.e. no path info at all)
  # with tempfile()

  # So we generate with and remove everything that's not alphanumeric
  tempfilepath <- tempfile(tmpdir = "/")

  tempbare <- gsub("[^[:alnum:]]", "", tempfilepath)

  return(tempbare)
}


#' Prepare a .Rprofile for staging
#'
#' This function takes an .Rprofile and
#' modifies it with any proxy setup that is required,
#' using the look-up included in the package and using the
#' local environment variables.
#'
#' We first test the SHINYSENDER_SERVER environment variable against the servers
#' specified in shinysender:::server_proxy_overrides.  If SHINYSENDER_SERVER matches
#' the name of any of the entries in this vector, we default to using its value as
#' both the http and https proxy.  This is used to handle the fact that the UoM pilot
#' server requires a web proxy.
#'
#' This can be overriden by setting the environment variable SHINYSENDER_PROXY
#' (to set both http and https proxy
#' to the same value on the remote server),
#' or SHINYSENDER_HTTP_PROXY and/or SHINYSENDER_HTTPS_PROXY are set to set
#'  each environment variable independently.
#'
#' In any case, the full URL for the proxy server(s) should be given, e.g.
#' "http://myproxy.com:3128"
#'
#' @param our_profile Character vector containing the .Rprofile you wish to
#' modify
#'
#' @return A character vector containing the (potentially) modified .Rprofile
prepareRprofile <- function(our_profile) {


  remote_proxy = Sys.getenv("SHINYSENDER_PROXY")
  remote_proxy_http = Sys.getenv("SHINYSENDER_PROXY_HTTP")
  remote_proxy_https = Sys.getenv("SHINYSENDER_PROXY_HTTPS")

  if (remote_proxy != "") {
    if (remote_proxy_http != "" | remote_proxy_https != "" ) {
      stop("If specifying SHINYSENDER_PROXY, SHINYSENDER_PROXY_HTTPS and SHINYSENDER_PROXY_HTTP must both be unset")
    }
  }

  # If any of the proxy variables have been specified we'll use them
  # regardless of whether we find an override
  setproxy = FALSE
  if (remote_proxy != "" | remote_proxy_http != "" | remote_proxy_https != "") {
    setproxy = TRUE
  }


  if (!setproxy) {
    # Get the remote server, to test if we need to automatically set a proxy
    # Note this will set both http and https proxies
    remote_server = Sys.getenv("SHINYSENDER_SERVER")

    remote_proxy_override = server_proxy_overrides[names(server_proxy_overrides) == remote_server]

    if (length(remote_proxy_override) > 1)
      stop("Duplicate proxy overrides detected for server")

    if (length(remote_proxy_override) == 0)
      remote_proxy_override = ""

    remote_proxy = remote_proxy_override


  }


  # Lines containing the proxy spec will be added to this vector
  proxy_fragment <- character(0)

  # Set http/https proxies if single proxy specified
  if (remote_proxy != "") {
    if (remote_proxy_http != "" | remote_proxy_https != "" ) {
      stop("If specifying SHINYSENDER_PROXY, SHINYSENDER_PROXY_HTTPS and SHINYSENDER_PROXY_HTTP must both be unset")
    }

    remote_proxy_http = remote_proxy
    remote_proxy_https = remote_proxy

  }

  # TODO check it's a valid URL.
  if (remote_proxy_http != "") {

    if (!validate_url(remote_proxy_http)) {
      stop("Invalid proxy string for SHINYSENDER_PROXY_HTTP")
    }

    proxystring <- paste0('Sys.setenv(http_proxy="', remote_proxy_http, '")')
    proxy_fragment <- c(proxy_fragment, proxystring)

  }

  if (remote_proxy_https != "") {

    if (!validate_url(remote_proxy_https)) {
      stop("Invalid proxy string for SHINYSENDER_PROXY_HTTPS")
    }

    proxystring <- paste0('Sys.setenv(https_proxy="', remote_proxy_https, '")')
    proxy_fragment <- c(proxy_fragment, proxystring)

  }


  if (length(proxy_fragment) > 0) {
    message("Overriding default proxy for staging")
    # Update the proxy

    # Find where the stub is
    stubstring <- "## Proxy Placeholder ##"
    proxypos <- grep(stubstring, our_profile, fixed = TRUE)
    if (length(proxypos) != 1) {
      stop("Could not find placeholder to add web proxy")
    }

    our_profile <- append(our_profile, proxy_fragment, after = proxypos)

  }

  return(our_profile)

}


#' Validate a URL
#'
#' Based on regex at https://cran.r-project.org/web/packages/rex/vignettes/url_parsing.html
#' with ftp removed
#'
#' @param url The URL(s) to validate
#' @return TRUE if potentially valid URL, FALSE otherwise
#'
validate_url <- function(url) {


  urlregex <- "^(?:(?:http(?:s)?)://)(?:\\S+(?::(?:\\S)*)?@)?(?:(?:[a-z0-9\u00a1-\uffff](?:-)*)*(?:[a-z0-9\u00a1-\uffff])+)(?:\\.(?:[a-z0-9\u00a1-\uffff](?:-)*)*(?:[a-z0-9\u00a1-\uffff])+)*(?:\\.(?:[a-z0-9\u00a1-\uffff]){2,})(?::(?:\\d){2,5})?(?:/(?:\\S)*)?$"

  grepl(urlregex, url)

}
