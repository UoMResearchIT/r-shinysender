test_that("Remote package installation testing works", {
  has_package <- function(session, remoteRRun) {
    # ssh_exec_wait returns shell's exit code, i.e. 0 for success
    if (grepl("installedPackage", remoteRRun)) {
      return(0)
    } else {
      return(1)
    }
  }

  mockery::stub(
    ss_is_remote_package_installed,
    'ssh::ssh_exec_wait',
    has_package
  )

  expect_true(ss_is_remote_package_installed(fakessh(), "installedPackage"))
  expect_false(ss_is_remote_package_installed(fakessh(), "missingPackage"))
})

test_that("Remote directory creation works", {
  m <- mockery::mock()

  mockery::stub(ss_setupserver, 'does_directory_exist', FALSE)
  mockery::stub(ss_setupserver, 'create_remote_dir', m)
  mockery::stub(ss_setupserver, 'ss_is_remote_package_installed', TRUE)

  # Setup server
  ss_setupserver(fakessh())

  expected_args <- list(
    list(structure("dummy ssh session", class = "ssh"), "ShinyApps"),
    list(structure("dummy ssh session", class = "ssh"), "ShinyApps_staging")
  )

  # Unsure why mockery::expect_args() doesn't work
  expect_equal(mockery::mock_args(m), expected_args)
})

test_that("remote package detection works", {
  mockery::stub(ss_setupserver, 'does_directory_exist', FALSE)
  mockery::stub(ss_setupserver, 'create_remote_dir', TRUE)
  mockery::stub(ss_setupserver, 'ss_is_remote_package_installed', FALSE)

  # Setup server
  expect_error(
    ss_setupserver(fakessh()),
    "The following packages are not installed .*"
  )
})
