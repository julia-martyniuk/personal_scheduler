test_that("simulate_burnout returns correct structure", {
  df <- simulate_burnout(n_tasks = 5, p = 0.5, threshold = 3, days = 10, reps = 100)

  # Check that output is a data frame
  expect_s3_class(df, "data.frame")

  # Check expected number of columns and column names
  expect_equal(ncol(df), 2)
  expect_equal(colnames(df), c("Day", "BurnoutRisk"))

  # Check number of rows matches simulation length
  expect_equal(nrow(df), 10)
})
