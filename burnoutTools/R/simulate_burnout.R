#' Simulate burnout risk over time
#'
#' runs a Monte Carlo simulation to estimate the probability of exceeding a burnout threshold
#' over a specified number of days.
#'
#' @param n_tasks Initial number of pending tasks.
#' @param p Probability of completing each task (0 to 1).
#' @param threshold Threshold of pending tasks that triggers burnout risk.
#' @param days Total days to simulate.
#' @param reps Number of simulation repetitions.
#'
#' @return A data frame with columns `Day` and `BurnoutRisk`.
#' @export
simulate_burnout <- function(n_tasks, p, threshold = 3, days = 30, reps = 1000) {
  stopifnot(
    is.numeric(n_tasks), n_tasks >= 0,
    is.numeric(p), p >= 0, p <= 1,
    is.numeric(threshold), threshold >= 0,
    is.numeric(days), days > 0,
    is.numeric(reps), reps > 0
  )

  simulate_burnout_cpp(n_tasks, p, threshold, days, reps)
}
