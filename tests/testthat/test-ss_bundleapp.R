test_that("app bundling works", {
  appdir <- tempfile("dir")

  testapp <- create_local_shiny_app(dir = appdir)
  bundlefile <- ss_bundleapp(appdir, "testapp")

  # TODO check a sensible bundle
  expect_true(grepl("\\.tar.gz$", bundlefile))
})
