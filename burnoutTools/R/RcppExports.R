# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

simulate_burnout_cpp <- function(n_tasks, p, threshold, days, reps, task_arrival_rate = 0.5) {
    .Call(`_burnoutTools_simulate_burnout_cpp`, n_tasks, p, threshold, days, reps, task_arrival_rate)
}

