#' Simplified, local version of ss_setupRprofile and friends
setupRprofile <- function(projectpath, staging = FALSE) {

  # Get contents of projectpath/.Rprofile, if it exists
  original_rprofile_path <- paste0(projectpath / ".Rprofile")
  if (file.exists(original_rprofile_path)) {
    original_Rprofile <- readLines(original_rprofile_path)
  } else {
    original_Rprofile <- character(0) # empty profile
  }

  # Read the default .Rprofile (to be appended)
  if (staging) {
    staging_profile_template <- readLines(ShinySenderRprofilePathStaging())
    profile_patch <- prepareRprofile(staging_profile_template)
  } else {
    profile_patch <- readLines(ShinySenderRprofilePath())
  }

  # Patch the original .Rprofile with the new lines

  # (shinysenderize_Rprofile expects a path to a file)
  temp_profile_path <- tempfile()
  on.exit(file.remove(temp_profile_path), add = TRUE)
  writeLines(profile_patch, temp_profile_path)

  modified_Rprofile <- shinysenderize_Rprofile(original_Rprofile,
                                               rprofilefragmentpath = temp_profile_path)

  # Write the modified .Rprofile back to the project path
  writeLines(modified_Rprofile, original_rprofile_path)
  
  # Hard-replace the .Renviron file by ours
  Renviron <- system.file("remoteprofile/shinysender_Renviron", package = "shinysender", mustWork = TRUE)
  writeLines(Renviron, con = paste0(projectpath, "/.Renviron"))
}

#' Simplified, local version of ss_uploadaddin
deploylocal <- function(appDir, appName, ..., overwrite = FALSE,
  .ShinyApps = "~/ShinyApps", .ShinyAppsStaging = "~/ShinyApps_staging") {

  if (!ss_isAppNameValid(appName)) {
    stop(appName, " is not a valid Shiny app name")
  }

  # Check required directories exist
  for (rd in c(.ShinyApps, .ShinyAppsStaging)) {
    stopifnot(dir.exists(rd))
  }

  # list subdirectories in ShinyApps
  installedApps <- list.dirs(.ShinyApps, full.names = FALSE, recursive = FALSE)

  # Note this is case sensitive, since Shiny server is
  appExistsOnRemote <- appName %in% installedApps
  if (appExistsOnRemote) {
    if (!overwrite) {
      stop(appName, " is already on the server")
    } else {
      message("Overwriting existing app: ", appName)
    }
  }

  # We probably don't want multiple apps differing only in case,
  # so warn if the user has done this.
  casecheck  <- tolower(appName) %in% tolower(installedApps)
  if (!appExistsOnRemote && casecheck) {
    casedups <- installedApps[tolower(appName) == tolower(installedApps)]
    warning(paste("An app with the same name but different case exists on the server. You may wish to delete these using ss_deleteapp():",
                  casedups))
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

  # This runs instead of scp_upload
  file.rename(bundleFile, paste0(.ShinyAppsStaging, "/", bundleBareFile))
  bundleFile <- paste0(.ShinyAppsStaging, "/", bundleBareFile)

  # Append a random string to the appname to use for staging
  stagingDir <- paste0(.ShinyAppsStaging, "/", appName, tempBare())
  dir.create(stagingDir)

  # Clean-up staging directory. Do this via on.exit so that it will still happen
  # even if the decompression fails
  on.exit({
    file.remove(bundleFile)
    if (dir.exists(stagingDir)) unlink(stagingDir, recursive = TRUE, force = TRUE)
  }, add = TRUE)

  out  <- system2("tar", args = c("xzf", bundleFile, "-C", stagingDir), stdout = TRUE, stderr = TRUE)
  if (attr(out,"status") > 0) {
    stop("Error unpacking bundle: ", out)
  }

  # Setup the app's .Rprofile
  message("Setting up staging environment")

  setupRprofile(stagingDir, staging = TRUE)

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
      github_pat_insert = paste0('Sys.setenv(GITHUB_PAT = "', github_pat, '"); ')

  # # Project parameter doesn't seem to work, so cd to project directory first
  # # Turn off history for this since we don't want the PAT to be saved anywhere
  # remotecommand <- paste0(
  #   "set +o history && cd ", stagingDir,
  #   " && Rscript -e '", github_pat_insert,
  #   " options(renv.verbose = FALSE);",
  #   " lockfile <- renv:::renv_lockfile_from_manifest(\"manifest.json\");",
  #   " lockfile$R$Version <- as.character(lockfile$R$Version);", # see https://github.com/rstudio/renv/issues/1667
  #   " renv::lockfile_write(lockfile);",
  #   " renv::activate()'",
  #   " && Rscript -e '", github_pat_insert,"renv::restore(); renv::status()'")

  # retval = system(remotecommand, intern = TRUE)
  # if (attr(retval, "status") != 0) {
  #   stop("Library restoration failed: ", paste(retval, collapse = "\n"))
  # }

  out = callr::r(
    function() {
      readRenviron('.Renviron');  # not picked up by default
      options(renv.verbose = TRUE)
      lockfile <- renv:::renv_lockfile_from_manifest("manifest.json")
      lockfile$R$Version <- as.character(lockfile$R$Version) # see https://github.com/rstudio/renv/issues/1667
      renv::lockfile_write(lockfile)
      renv::load('.')
      renv::restore()
      renv::repair()
      renv::activate()
      list(project = renv::project(),
           synchronized = renv::status()$synchronized,
           messages = capture.output(renv::status()))
    },
    user_profile = 'project', # use .Rprofile in stagingDir
    wd = stagingDir,
    env = c(GITHUB_PAT = github_pat)
  )

  if (!out$synchronized) {
    warning("Library restoration failed", out$messages)
  }

  # Replace the staging .Rprofile with the deployment one
  message("Setting up deployment environment")
  setupRprofile(stagingDir, staging = FALSE)

  # If we get here we've uploaded it to staging OK
  # So delete the old app
  if (appExistsOnRemote) {

    message("Removing existing version of app")
    unlink(paste0(.ShinyApps, "/", appName), recursive = TRUE, force = TRUE)
  }

  message("Deploying app from staging location")
  dir.rename(stagingDir, paste0(.ShinyApps, "/", appName))

  message("App deployed to: ", appName)

  # Derive deployed app URL
  # TODO This assumes we always deploy to host/user/appname
  # which is set on the remote in the server config.

  # sessionInfo <- ssh::ssh_session_info(session)

  # sessionUser <- sessionInfo$user
  # sessionServer <- sessionInfo$host

  # if (!is.null(sessionUser) & !is.null(sessionServer)) {
  #   remoteURL <- paste0("https://", sessionServer, "/",
  #                       sessionUser, "/", appName)
  #   message("App deployed to:")
  #   message(remoteURL)
  }
}