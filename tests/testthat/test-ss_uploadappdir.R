
test_that("URL validation works", {

  expect_true(validate_url("http://www.goodurl.com"))
  expect_true(validate_url("https://www.goodurl.com"))
  expect_false(validate_url("ftp://badurl.com"))
  # We require a protocol
  expect_false(validate_url("www.goodurl.com"))
  expect_false(validate_url("www.goodurl.com"))

  expect_false(validate_url("hello'bobby'tables"))

})

{

  # Unset all of the environment variables we might be using
  # in these tests, in case we're picking them up from the user's
  # .Rprofile
  withr::local_envvar( c("SHINYSENDER_PROXY"="",
                         "SHINYSENDER_PROXY_HTTP"="",
                         "SHINYSENDER_PROXY_HTTPS"="",
                         "SHINYSENDER_SERVER"=""
  ))



  test_that("only direct_home method works", {



    testapp <- create_local_shiny_app()
    expect_error(ss_uploadappdir(fakessh(), testapp, "myapp", method = "not_direct_home"))



  })


  test_that("Remote directory detection works", {


    mockery::stub(ss_uploadappdir, 'does_directory_exist', FALSE)

    testapp <- create_local_shiny_app()
    expect_warning(ss_uploadappdir(fakessh, testapp, "myapp"),
                   regexp= "does not exist\\. Run ss_setupserver\\(\\) to create")


  })

  test_that("App case detection works", {


    mockery::stub(ss_uploadappdir, 'does_directory_exist', TRUE)
    mockery::stub(ss_uploadappdir, 'ss_listdir', c("app1", "app2", "app3"))

    expect_error(
      expect_warning(ss_uploadappdir(fakessh(),
                                     create_local_shiny_app(),
                                     "App1"),
                     "^An app with the same name but different case exists on the server"), # Warning we want
      "^Upload failed$") # Since we can't actually upload to a fake ssh connection


  })


  test_that("Proxy specification works", {
    withr::local_envvar( c("SHINYSENDER_PROXY"="http://myproxy.com:3128",
                           "SHINYSENDER_PROXY_HTTP"="http://anotherprox.com"))
    expect_error(
      prepareRprofile(ShinySenderRprofilePathStaging()),
      "^If specifying SHINYSENDER_PROXY, SHINYSENDER_PROXY_HTTPS and SHINYSENDER_PROXY_HTTP must both be unset$"
    )

  })

  test_that("Proxy specification works", {
    withr::local_envvar( c("SHINYSENDER_PROXY"="http://myproxy.com:3128",
                           "SHINYSENDER_PROXY_HTTPS"="http://anotherprox.com"))
    expect_error(
      prepareRprofile(ShinySenderRprofilePathStaging()),
      "^If specifying SHINYSENDER_PROXY, SHINYSENDER_PROXY_HTTPS and SHINYSENDER_PROXY_HTTP must both be unset$"
    )

  })

  test_that("Proxy specification works", {
    withr::local_envvar( c("SHINYSENDER_PROXY"="http://myproxy.com:3128",
                           "SHINYSENDER_PROXY_HTTP"="http://anotherprox.com",
                           "SHINYSENDER_PROXY_HTTPS"="http://yetanotherprox.com"
    ))
    expect_error(
      prepareRprofile(ShinySenderRprofilePathStaging()),
      "^If specifying SHINYSENDER_PROXY, SHINYSENDER_PROXY_HTTPS and SHINYSENDER_PROXY_HTTP must both be unset$"
    )

  })


  test_that("Proxy specification works", {
    withr::local_envvar( c("SHINYSENDER_PROXY"="http://myproxy.com:3128" ))


    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://myproxy.com:3128")',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://myproxy.com:3128")',
                 fixed = TRUE, all = FALSE
    )

  })

  test_that("Proxy specification works", {
    withr::local_envvar( c( "SHINYSENDER_PROXY_HTTP"="http://anotherprox.com",
                            "SHINYSENDER_PROXY_HTTPS"="http://yetanotherprox.com",
                            "SHINYSENDER_PROXY"="", # Unset in case set in our .Rprofile
                            "SHINYSENDER_SERVER"="" # Unset in case set in our .Rprofile
    ))

    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://anotherprox.com',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://yetanotherprox.com',
                 fixed = TRUE, all = FALSE
    )

  })

  test_that("URL trapping works", {

    withr::local_envvar( c( "SHINYSENDER_PROXY_HTTP"="xxx://anotherprox.com",
                            "SHINYSENDER_PROXY_HTTPS"="http://yetanotherprox.com",
                            "SHINYSENDER_PROXY"="", # Unset in case set in our .Rprofile
                            "SHINYSENDER_SERVER"="" # Unset in case set in our .Rprofile
    ))
    expect_error(prepareRprofile(orig_profile), "^Invalid proxy string for SHINYSENDER_PROXY_HTTP$")

  })

  test_that("URL trapping works", {

    withr::local_envvar( c( "SHINYSENDER_PROXY_HTTP"="http://anotherprox.com",
                            "SHINYSENDER_PROXY_HTTPS"="xxx://yetanotherprox.com",
                            "SHINYSENDER_PROXY"="", # Unset in case set in our .Rprofile
                            "SHINYSENDER_SERVER"="" # Unset in case set in our .Rprofile
    ))
    expect_error(prepareRprofile(orig_profile), "^Invalid proxy string for SHINYSENDER_PROXY_HTTPS$")

  })



  test_that("Proxy specification works with UoM server", {
    withr::local_envvar( c( "SHINYSENDER_PROXY_HTTP"="http://anotherprox.com",
                            "SHINYSENDER_PROXY_HTTPS"="http://yetanotherprox.com",
                            "SHINYSENDER_PROXY"="", # Unset in case set in our .Rprofile
                            "SHINYSENDER_SERVER"="shiny.its.manchester.ac.uk"
    ))

    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://anotherprox.com',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://yetanotherprox.com',
                 fixed = TRUE, all = FALSE
    )

  })
  test_that("We don't modify rprofile if no proxy", {
    # Ensure variables are unset, in case we pick any up from user's .Rprofile
    withr::local_envvar( c( "SHINYSENDER_PROXY_HTTP"="",
                            "SHINYSENDER_PROXY_HTTPS"="",
                            "SHINYSENDER_PROXY"="",
                            "SHINYSENDER_SERVER"=""
    ))
    # File should be identical if no proxy specified
    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    expect_equal(orig_profile,
                 prepareRprofile(orig_profile))


  } )


  test_that("Modification fails if there's no placeholder",{
    withr::local_envvar( c("SHINYSENDER_PROXY"="http://myproxy.com:3128" ))
    # The deployment Rprofile doesn't have a proxy placeholder
    orig_profile <- readLines(ShinySenderRprofilePath())

    expect_error(prepareRprofile(orig_profile),
                 "^Could not find placeholder to add web proxy$")


  })


  test_that("We set a proxy if the SHINYSENDER_SERVER variable is certain specific servers",{

    withr::local_envvar("SHINYSENDER_SERVER"="shiny.its.manchester.ac.uk")

    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://webproxy.its.manchester.ac.uk:3128/")',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://webproxy.its.manchester.ac.uk:3128/")',
                 fixed = TRUE, all = FALSE
    )



  })




  test_that("We set a proxy if the SHINYSENDER_SERVER variable is certain specific servers",{
    # Dev server TODO - speak to Jok about getting an internal DNS entry for this
    withr::local_envvar("SHINYSENDER_SERVER"="10.99.97.199"
    )

    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://webproxy.its.manchester.ac.uk:3128/")',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://webproxy.its.manchester.ac.uk:3128/")',
                 fixed = TRUE, all = FALSE
    )



  })



  test_that("We can still override the default proxy if we're using a specific server",{

    withr::local_envvar("SHINYSENDER_SERVER"="shiny.its.manchester.ac.uk",
                        "SHINYSENDER_PROXY"="http://myspecialproxy.co.uk:1234")

    orig_profile <- readLines(ShinySenderRprofilePathStaging())

    mod_profile <- prepareRprofile(orig_profile)

    expect_match(mod_profile,
                 'Sys.setenv(http_proxy="http://myspecialproxy.co.uk:1234")',
                 fixed = TRUE, all = FALSE
    )

    expect_match(mod_profile,
                 'Sys.setenv(https_proxy="http://myspecialproxy.co.uk:1234")',
                 fixed = TRUE, all = FALSE
    )



  })


}


