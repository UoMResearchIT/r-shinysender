# .Rprofile code to use user's packrat cache
# (to avoid recompiling packages for each app)
# and to enable Packrat on startup


message("Setting up packrat cache")
Sys.setenv(R_PACKRAT_CACHE_DIR = "~/R/packratcache")
packrat::set_opts(use.cache=TRUE)

packrat::on()
