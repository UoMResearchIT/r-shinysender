test_that("We can find Rprofile fragments", {
  expect_match(ShinySenderRprofilePath(), "shinysender_Rprofile")
  expect_match(ShinySenderRprofilePathStaging(), "shinysender_staging_Rprofile")
})

test_that("RProfile updating works", {
  Rprofiles <- list(
    # A short Rprofile
    c("# My Rprofile", "# Doesn't do much"),
    # An empty Rprofile
    character(0)
  )

  for (Rprofile in Rprofiles) {
    #Shinysenderize it
    RprofileFilled <- shinysenderize_Rprofile(Rprofile)

    # Our fragment
    ssRprofile <- readLines(ShinySenderRprofilePath())

    # We should get back our profile + fragment
    expect_equal(c(Rprofile, ssRprofile), RprofileFilled)

    # Updating the filled profile shouldn't change it
    expect_equal(RprofileFilled, shinysenderize_Rprofile(RprofileFilled))

    # Should be able to remove what we've added
    expect_equal(
      Rprofile,
      shinysenderize_Rprofile(RprofileFilled, action = "delete")
    )
  }

  expect_error(shinysenderize_Rprofile(c(1, 2, 3)))
})

test_that("We can convert application names to paths", {
  expect_equal(appnameToPath("testapp"), "~/ShinyApps/testapp")
  expect_error(appnameToPath("*badappname"))
})


test_that("We can handle remote rprofiles", {
  fakesession <- fakessh()
  expect_error(
    get_remote_Rprofile(fakesession, appname = NULL, remotepath = NULL),
    "Must specify appname or remotepath, not both"
  )

  expect_error(
    get_remote_Rprofile(
      fakesession,
      appname = "myapp",
      remotepath = "~/mypath"
    ),
    "Must specify appname or remotepath, not both"
  )
})


test_that("We can detect a missing remote Rprofile", {
  mock_failed_ssh_command <- function(session, command, error) {
    myobject <- list()
    myobject$status <- 1

    return(myobject)
  }

  fakesession <- fakessh()

  mockery::stub(
    get_remote_Rprofile,
    'ssh::ssh_exec_internal',
    mock_failed_ssh_command
  )

  expect_error(
    expect_message(
      get_remote_Rprofile(fakesession, appname = "myapp", warnmissing = TRUE),
      "No remote \\.Rprofile found"
    ), # Error we care about
    "argument 'x' must be a raw vector"
  ) # Error from not having a real ssh connection
})
