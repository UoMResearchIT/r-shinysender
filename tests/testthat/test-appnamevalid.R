test_that("App name is length 1 or more", {
  expect_false(ss_isAppNameValid(""))
  expect_true(ss_isAppNameValid("A"))
})

test_that("We've got a character vector of length", {
  expect_false(ss_isAppNameValid(c("a", "b")))
  expect_false(ss_isAppNameValid(1))
  expect_false(ss_isAppNameValid(c(1,2)))
  expect_true(ss_isAppNameValid("app"))

})

test_that("We'not got non alphanumeric characters", {

  expect_false(ss_isAppNameValid("ab_c"))
  expect_false(ss_isAppNameValid("~testing"))
  expect_false(ss_isAppNameValid("@hello"))
  expect_false(ss_isAppNameValid("testing_"))

  expect_true(ss_isAppNameValid("JustLetters"))
  expect_true(ss_isAppNameValid("1234"))
  expect_true(ss_isAppNameValid("Letters1Numbers2"))

  expect_false(ss_isAppNameValid("No spaces please"))


})
