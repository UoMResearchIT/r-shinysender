test_that("only direct_home method works", {



  testapp <- create_local_shiny_app()
  expect_error(ss_uploadappdir(fakessh, testapp, "myapp", method = "not_direct_home"))



})


test_that("Remote directory detection works", {


  stub(ss_uploadappdir, 'does_directory_exist', FALSE)

  testapp <- create_local_shiny_app()
  expect_warning(ss_uploadappdir(fakessh, testapp, "myapp"),
               regexp= "does not exist\\. Run ss_setupserver\\(\\) to create")


})

test_that("App case detection works", {


  stub(ss_uploadappdir, 'does_directory_exist', TRUE)
  stub(ss_uploadappdir, 'ss_listdir', c("app1", "app2", "app3"))

    expect_error(
      expect_warning(ss_uploadappdir(fakessh,
                                     create_local_shiny_app(),
                                     "App1"),
                     "An app with the same name but different case exists on the server"), # Warning we want
      "Upload failed") # Since we can't actually upload to a fake ssh connection


})
