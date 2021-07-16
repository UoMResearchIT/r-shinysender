# .Rprofile code to use user's packrat cache
# (to avoid recompiling packages for each app)
# and to enable Packrat on startup


message("Setting up packrat cache")
Sys.setenv(R_PACKRAT_CACHE_DIR = "~/R/packratcache")
packrat::set_opts(use.cache=TRUE)


# Test if we're running a local app, or within a Shiny server
# Complicated way with PIDs (we can't use SHINY_ env vars as not set at
# this point)

# We get the process PID, then find out the name of the parent PID
ourpid <- Sys.getpid()
pidargs <- c(paste0("-p $(ps -o ppid= -p ", ourpid, ")"),  "-o comm=")
parentcmd <- system2("ps", args = pidargs, stdout = TRUE)
# Shiny runs the app in an su environment (it seems), so the
# parent command is "su"
# TODO - check if su's parent is shiny?
# TODO clean up temp vars and set environment variable indicating running
# in a shiny server
message(parentcmd)
if(parentcmd == "su"){
  message("Running in shiny server")
  packrat::on()
}
