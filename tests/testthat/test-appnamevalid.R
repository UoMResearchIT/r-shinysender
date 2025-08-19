test_that("App name is 4 to 63 characters long", {
  expect_false(ss_isAppNameValid(""))
  expect_false(ss_isAppNameValid("abc"))
  expect_false(ss_isAppNameValid(strrep("a", 64)))
  expect_true(ss_isAppNameValid("appname"))
})

test_that("Only strings allowed", {
  expect_false(ss_isAppNameValid(c("a", "b")))
  expect_false(ss_isAppNameValid(1))
  expect_false(ss_isAppNameValid(c(1, 2)))
  expect_true(ss_isAppNameValid("appname"))
})

test_that("Only alphanumeric characters, dash, and underscore", {
  expect_false(ss_isAppNameValid("~testing"))
  expect_false(ss_isAppNameValid("@hello"))
  expect_false(ss_isAppNameValid("testing!"))

  expect_true(ss_isAppNameValid("JustLetters"))
  expect_true(ss_isAppNameValid("1234"))
  expect_true(ss_isAppNameValid("Letters1Numbers2"))
  expect_true(ss_isAppNameValid("ab_c-de"))

  expect_false(ss_isAppNameValid("No spaces please"))
})
