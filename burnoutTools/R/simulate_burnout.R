#' Simulate Burnout Forecast
#'
#' @param n_tasks Integer. Number of deadlines pending.
#' @param p Numeric. Completion probability (0–1).
#' @param threshold Integer. Max tasks before burnout risk.
#' @param days Integer. Simulation window (default 30).
#' @param reps Integer. Repetitions (default 1000).
#'
#' @return Data frame with burnout probabilities
#' @export
simulate_burnout <- function(n_tasks, p, threshold = 3, days = 30, reps = 1000) {
  simulate_burnout_cpp(n_tasks, p, threshold, days, reps)
}
