# Generate a minimal Shiny app in its own directory
# Based on https://testthat.r-lib.org/articles/test-fixtures.html

create_local_shiny_app <- function(
  dir = fs::file_temp(),
  env = parent.frame(),
  singlefile = TRUE
) {
  # create new folder and package
  dir.create(dir) # A
  withr::defer(fs::dir_delete(dir), envir = env) # -A

  old_project_dir <- getwd() # B
  setwd(dir)
  ui.R <- c(
    'library(shiny)',
    'shinyUI(fluidPage(',
    'titlePanel("Old Faithful Geyser Data"),',
    'sidebarLayout(',
    'sidebarPanel(',
    'sliderInput("bins",',
    '"Number of bins:",',
    'min = 1,',
    'max = 50,',
    'value = 30)',
    '),',
    'mainPanel(',
    'plotOutput("distPlot")',
    ')',
    ')',
    '))'
  )

  server.R <- c(
    'library(shiny)',
    'shinyServer(function(input, output) {',
    'output$distPlot <- renderPlot({',
    'x    <- faithful[, 2]',
    'bins <- seq(min(x), max(x), length.out = input$bins + 1)',
    'hist(x, breaks = bins, col = "darkgray", border = "white")',
    '})',
    '})'
  )

  # Spit out to multiple / single files
  if (!singlefile) {
    uiConn <- file("ui.R")
    serverConn <- file("server.R")
  } else {
    uiConn <- file("app.R")
    serverConn <- uiConn
  }

  writeLines(ui.R, uiConn)
  writeLines(server.R, serverConn)

  close(uiConn)
  if (!singlefile) {
    # Can't close a file twice
    close(serverConn)
  }

  withr::defer(setwd(old_project_dir), envir = env) # -B

  return(dir)
}


# Return a fake ssh connection
fakessh <- function() {
  dummysession <- "dummy ssh session"
  class(dummysession) <- "ssh"

  return(dummysession)
}
