test_that("simulate_burnout returns expected structure and content", {
  df <- simulate_burnout(
    n_tasks = 5,
    p = 0.5,
    threshold = 3,
    days = 10,
    reps = 100
  )

  # Check type and shape
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 10)

  # Check for required columns
  expected_cols <- c(
    "Day", "BurnoutRisk", "AvgPendingTasks", "Fatigue",
    "Summary_HighRiskDays", "Summary_PeakRiskDay", "Summary_MaxFatigue"
  )
  expect_true(all(expected_cols %in% names(df)))

  # Basic value checks
  expect_true(all(df$Day == 1:10))
  expect_true(all(df$BurnoutRisk >= 0 & df$BurnoutRisk <= 1))
})
