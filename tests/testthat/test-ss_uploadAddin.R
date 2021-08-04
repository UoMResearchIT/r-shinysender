test_that("Addin errors if required environment variables not set", {

    withr::with_envvar(new = c("SHINYSENDER_USER"="alice",
                               "SHINYSENDER_SERVER"=""),
                       {
                         expect_error(ss_upload_addin(),
                                      "You must set the SHINYSENDER_SERVER environment variable before using the addin.")
                       })

    withr::with_envvar(new = c("SHINYSENDER_USER"="",
                               "SHINYSENDER_SERVER"="myserver"),
                       {
                         expect_error(ss_upload_addin(),
                                      "You must set the SHINYSENDER_USER environment variable before using the addin.")
                       })
    # Test both missing
    # Expect both missing environment variables to be mentioned in the error message
    # In either order
    withr::with_envvar(new = c("SHINYSENDER_USER"="",
                               "SHINYSENDER_SERVER"=""),
                       {
                         expect_error(ss_upload_addin(), "(SHINYSENDER_USER.+SHINYSENDER_SERVER|SHINYSENDER_SERVER.+SHINYSENDER_USER)")
                       })
})
