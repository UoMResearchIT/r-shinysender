# Generate a minimal Shiny app in its own directory

create_local_shiny_app <- function(dir = fs::file_temp(), env = parent.frame()) {

  fs::dir_create(dir)
  withr::defer(fs::dir_delete(dir), envir = env)

  # TODO make a plausible shiny app
  fs::file_create(paste0(dir, "/app.R"))



}
