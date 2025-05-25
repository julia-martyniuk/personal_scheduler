test_that("simulate_burnout returns correct structure", {
  df <- simulate_burnout(n_tasks = 5, p = 0.5, threshold = 3, days = 10, reps = 100)

  expect_s3_class(df, "data.frame")
  expect_equal(ncol(df), 2)
  expect_equal(colnames(df), c("Day", "BurnoutRisk"))
  expect_equal(nrow(df), 10)
})
