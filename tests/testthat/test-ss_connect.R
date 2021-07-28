test_that("we error if no username or server", {
  expect_error(ss_connect(username=""), "Pass username parameter")

  expect_error(ss_connect(server=""), "Pass server parameter")
})

test_that("We error if host does not resolve", {
  expect_error(ss_connect(username="dummy", server="nothere.notdomain"),
               "Failed to resolve hostname")

})
