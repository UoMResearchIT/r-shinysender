test_that("we error if no username or server", {
  expect_error(ss_connect(username=""), "Pass username parameter")

  expect_error(ss_connect(server=""), "Pass server parameter")
})

# Note the following test is slow
test_that("We error if host does not resolve", {
  expect_error(ss_connect(username="dummy", server="nothere.notdomain"),
               "Failed to resolve hostname")

})


test_that("Username detection works", {

  if (requireNamespace("withr", quietly = TRUE)) {
    withr::with_envvar(new = c("USER"="",
                               "USERNAME"="",
                               "SHINYSENDER_USER"=""),
                       {
                         expect_error(getUserName(), "Could not determine username")
                       })

    withr::with_envvar(new = c("USER"="alice",
                               "USERNAME"="",
                               "SHINYSENDER_USER"=""),
                       {
                         expect_equal(getUserName(), "alice")
                       })

    withr::with_envvar(new = c("USER"="",
                               "USERNAME"="alice",
                               "SHINYSENDER_USER"=""),
                       {
                         expect_equal(getUserName(), "alice")
                       })

    withr::with_envvar(new = c("USER"="alice",
                               "USERNAME"="alice",
                               "SHINYSENDER_USER"=""),
                       {
                         expect_equal(getUserName(), "alice")
                       })

    withr::with_envvar(new = c("USER"="alice",
                               "USERNAME"="bob",
                               "SHINYSENDER_USER"=""),
                       {
                         expect_error(getUserName(), "but not equal")
                       })


    # Check the override user works
    withr::with_envvar(new = c("SHINYSENDER_USER"="bob"),
                       {
                         expect_equal(getUserName(), "bob")
                       })

    withr::with_envvar(new = c("SHINYSENDER_USER"=" "),
                       {
                         expect_error(getUserName(), "Invalid username")
                       })

  }

})
