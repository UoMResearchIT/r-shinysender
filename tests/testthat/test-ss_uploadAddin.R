test_that("Addin errors if required environment variables not set", {

    withr::with_envvar(new = c("SHINYSENDER_USER"="alice",
                               "SHINYSENDER_SERVER"=""),
                       {
                         expect_error(ss_uploadAddin(),
                                      "You must set the SHINYSENDER_SERVER environment variable before using the addin.")
                       })

    withr::with_envvar(new = c("SHINYSENDER_USER"="",
                               "SHINYSENDER_SERVER"="myserver"),
                       {
                         expect_error(ss_uploadAddin(),
                                      "You must set the SHINYSENDER_USER environment variable before using the addin.")
                       })
    # Test both missing
    # Expect both missing environment variables to be mentioned in the error message
    # In either order
    withr::with_envvar(new = c("SHINYSENDER_USER"="",
                               "SHINYSENDER_SERVER"=""),
                       {
                         expect_error(ss_uploadAddin(), "(SHINYSENDER_USER.+SHINYSENDER_SERVER|SHINYSENDER_SERVER.+SHINYSENDER_USER)")
                       })
})
#

test_that("Addin errors if we try to publish an invalid app name", {

    withr::with_envvar(new = c("SHINYSENDER_USER"="alice",
                               "SHINYSENDER_REMOTENAME"="bad name",
                               "SHINYSENDER_SERVER"="127.0.0.1"),
                       {
                         expect_error(ss_uploadAddin(), "not a valid application name")
                       })


})
