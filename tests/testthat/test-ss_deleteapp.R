test_that("delete app parameter checking works", {
  fakesession <- fakessh()

  # Apps we pretend to have installed
  stub(ss_deleteapp, 'ss_listdir', c("fakeapp1", "fakeapp2", "fakeapp3"))
  stub(ss_deleteapp, 'ssh::ssh_exec_wait', 0) # Return code for success

  expect_error(
    ss_deleteapp(fakesession, "!badname"),
    "ss_isAppNameValid\\(appName\\) is not TRUE"
  ) # Better error needed
  expect_error(
    ss_deleteapp(fakesession, c("app1", "app2")),
    "length\\(appName\\) == 1 is not TRUE"
  ) # Better error needed

  expect_error(
    ss_deleteapp(fakesession, "notinstalledapp"),
    "App not installed on remote server"
  )

  # Answer no when prompted
  stub(ss_deleteapp, 'utils::askYesNo', FALSE)
  expect_error(ss_deleteapp(fakesession, "fakeapp1"), "Not deleting remote app")

  # Should delete when prompt = FALSE
  expect_equal(ss_deleteapp(fakesession, "fakeapp1", prompt = FALSE), 0) # Return code 0 for success
})

test_that("remote app deletion works", {
  fakesession <- fakessh()

  # Apps we pretend to have installed
  stub(ss_deleteapp, 'ss_listdir', c("fakeapp1", "fakeapp2", "fakeapp3"))
  stub(ss_deleteapp, 'ssh::ssh_exec_wait', 0) # Return code for success

  # Answer yes when prompted
  stub(ss_deleteapp, 'utils::askYesNo', TRUE)
  expect_equal(ss_deleteapp(fakesession, "fakeapp1"), 0) # Return code 0 for success
})
