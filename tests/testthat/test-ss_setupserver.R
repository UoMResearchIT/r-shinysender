test_that("Remote package installation testing works", {

  mockssh <- function(conname, keyfile){

    dummysession <- "dummy ssh session"
    class(dummysession) <- "ssh"

    return(dummysession)

  }

  has_package <- function(session, remoteRRun){
    # ssh_exec_wait returns shell's exit code, i.e. 0 for success
    if(grepl("installedPackage", remoteRRun))
      return(0)
    else
      return(1)
  }


  stub(ss_is_remote_package_installed, 'ssh::ssh_exec_wait', has_package)

  expect_true(ss_is_remote_package_installed(mockssh, "installedPackage"))
  expect_false(ss_is_remote_package_installed(mockssh, "missingPackage"))


})

