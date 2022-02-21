test_that("disconnection works", {

  mocksshdisconnect <- function(session){

    return(NULL)

  }

  stub(ss_disconnect, 'ssh::ssh_disconnect', mocksshdisconnect)

  expect_null(ss_disconnect(mocksshdisconnect))
})
