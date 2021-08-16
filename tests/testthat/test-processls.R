test_that("We can detect a shiny ap", {

  expect_false(isShinyApp(c()))
  expect_false(isShinyApp("a.R"))
  expect_false(isShinyApp(c("a.R","b.R")))

  expect_true(isShinyApp("app.R"))
  expect_true(isShinyApp(c("ui.R", "server.R")))
  expect_true(isShinyApp(c("a.R", "ui.R", "server.R")))
  expect_true(isShinyApp(c("a.R", "b.R", "ui.R", "server.R")))

  expect_true(isShinyApp(c("index.Rmd")))
  expect_true(isShinyApp(c("index.Rmd", "a.R")))

  # mixed types should fail
  expect_true(is.na(isShinyApp(c("app.R", "ui.R", "server.R"))))

  expect_true(is.na(isShinyApp(c("app.R", "index.Rmd"))))
  expect_true(is.na(isShinyApp(c("server.R", "index.Rmd"))))
  expect_true(is.na(isShinyApp(c("ui.R", "index.Rmd"))))
  expect_true(is.na(isShinyApp(c("ui.R", "server.R", "index.Rmd"))))
#

})
