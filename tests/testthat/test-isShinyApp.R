test_that("we can detect a shiny app", {
  has_single_file_app <- c("test", "app.R", "stuff.txt")
  has_multi_file_app <- c("test", "ui.R", "more stuff.txt", "server.R")
  has_no_app <- c("nothing.txt", "noapp.R")

  expect_true(isShinyApp(has_single_file_app))
  expect_true(isShinyApp(has_multi_file_app))
  expect_false(isShinyApp(has_no_app))

  # Case matters
  expect_false(isShinyApp(tolower(has_single_file_app)))
  expect_false(isShinyApp(tolower(has_multi_file_app)))

  # We don't want app.R and ui.R and server.R
  expect_equal(
    is.na(isShinyApp(c(has_single_file_app, has_multi_file_app))),
    TRUE
  )
})
