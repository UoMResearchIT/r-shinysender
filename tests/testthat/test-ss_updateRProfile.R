test_that("We can find Rprofile fragment", {
 expect_match(ShinySenderRprofilePath(), "shinysender_Rprofile")
})

test_that("RProfile updating works", {
  Rprofiles <- list(
    # A short Rprofile
    c("# My Rprofile", "# Doesn't do much"),
    # An empty Rprofile
    character(0)
  )

  for(Rprofile in Rprofiles) {
    #Shinysenderize it
    RprofileFilled <- shinysenderize_Rprofile(Rprofile)

    # Our fragment
    ssRprofile <- readLines(ShinySenderRprofilePath())

    # We should get back our profile + fragment
    expect_equal(c(Rprofile, ssRprofile),  RprofileFilled)

    # Updating the filled profile shouldn't change it
    expect_equal(RprofileFilled,
                 shinysenderize_Rprofile(RprofileFilled))

    # Should be able to remove what we've added
    expect_equal(Rprofile,
                 shinysenderize_Rprofile(RprofileFilled, action = "delete"))
  }


  expect_error(shinysenderize_Rprofile(c(1,2,3)))

})
