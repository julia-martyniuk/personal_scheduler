#' Simulate burnout risk over time with dynamic workload
#'
#' This function performs a Monte Carlo simulation of task backlog and burnout risk over time.
#' It models daily task arrivals, task completions based on productivity, and feedback effects
#' such as fatigue (which lowers productivity) and recovery (which restores it gradually).
#'
#' @param n_tasks Integer. Number of pending tasks at Day 0.
#' @param p Numeric. Initial daily productivity (as a probability between 0 and 1).
#' @param threshold Integer. Burnout threshold — risk increases if pending tasks exceed this value.
#' @param days Integer. Number of simulation days.
#' @param reps Integer. Number of repetitions for averaging.
#' @param task_arrival_rate Numeric. Average number of new tasks arriving per day (Poisson-distributed).
#' @param seed Integer. Optional random seed for reproducibility.
#'
#' @return A data frame with the following columns:
#'   \describe{
#'     \item{Day}{Simulation day (1, 2, ..., days)}
#'     \item{BurnoutRisk}{Average estimated burnout risk per day}
#'     \item{AvgPendingTasks}{Average pending task count per day}
#'     \item{Fatigue}{Average daily productivity loss}
#'     \item{Summary_HighRiskDays}{Average number of days with burnout risk > 0.7}
#'     \item{Summary_PeakRiskDay}{Day when burnout risk peaked}
#'     \item{Summary_MaxFatigue}{Maximum observed fatigue across the simulation}
#'   }
#' @export
simulate_burnout <- function(n_tasks,
                             p,
                             threshold = 3,
                             days = 30,
                             reps = 1000,
                             task_arrival_rate = 0.5,
                             seed = 123) {

  # Basic argument checks
  stopifnot(
    is.numeric(n_tasks), n_tasks >= 0,
    is.numeric(p), p >= 0, p <= 1,
    is.numeric(threshold), threshold >= 0,
    is.numeric(days), days > 0,
    is.numeric(reps), reps > 0,
    is.numeric(task_arrival_rate), task_arrival_rate >= 0,
    is.numeric(seed)
  )

  # Extra safeguard to prevent invalid or unstable simulation runs
  if (p <= 0 || days <= 0 || reps <= 0) {
    stop("Invalid parameters: p > 0, days > 0, and reps > 0 are required.")
  }

  # Set seed to make results reproducible
  set.seed(seed)

  # Run the simulation using the underlying C++ function
  simulate_burnout_cpp(
    n_tasks = n_tasks,
    p = p,
    threshold = threshold,
    days = days,
    reps = reps,
    task_arrival_rate = task_arrival_rate
  )
}
