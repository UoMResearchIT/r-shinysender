test_that("Can get application listing", {

  fakesession <- fakessh()
  # Output of ssh::ssh_exec_internal(session, listappcmd)
  lsShinyApps <- list(status = 0L, stdout = as.raw(c(0x6c, 0x6f, 0x67, 0x0a, 0x6d,
                                                     0x69, 0x6e, 0x64, 0x74, 0x68, 0x65, 0x67, 0x61, 0x70, 0x0a, 0x70,
                                                     0x72, 0x6f, 0x74, 0x6f, 0x74, 0x79, 0x70, 0x69, 0x6e, 0x67, 0x77,
                                                     0x6f, 0x72, 0x6b, 0x73, 0x68, 0x6f, 0x70, 0x0a, 0x70, 0x72, 0x6f,
                                                     0x78, 0x79, 0x74, 0x65, 0x73, 0x74, 0x0a, 0x73, 0x68, 0x69, 0x6e,
                                                     0x79, 0x64, 0x65, 0x6d, 0x6f, 0x72, 0x6f, 0x62, 0x0a, 0x74, 0x65,
                                                     0x73, 0x74, 0x61, 0x70, 0x70, 0x32, 0x0a)), stderr = raw(0))

  stub(ss_listdir, 'ssh::ssh_exec_internal', lsShinyApps)


  expect_equal(ss_listdir(fakesession), c("log", "mindthegap", "prototypingworkshop", "proxytest", "shinydemorob",
                                           "testapp2"))


})
