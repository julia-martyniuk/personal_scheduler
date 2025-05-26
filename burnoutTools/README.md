# burnoutTools

burnoutTools is an R package made for a group project in the Advanced Programming in R course. It simulates how burnout risk changes over time based on task load, productivity, and fatigue. The simulation uses Monte Carlo methods, and the backend runs in C++ via Rcpp. Visualization is done with ggplot2.

## Features

- Simulates burnout risk over time using Monte Carlo simulations
- Includes task arrival and completion, fatigue buildup, and burnout risk logic
- Simulation core written in C++ for speed (via Rcpp)
- Plots daily burnout risk, fatigue, and pending tasks with ggplot2
- Can be used in Shiny apps or standalone scripts

## Installation

This package is not on CRAN. To install it locally:

```r
devtools::install("path/to/burnoutTools")
```

## Usage Example

```r
library(burnoutTools)

# Run simulation with 8 tasks and 60% productivity
result <- simulate_burnout(n_tasks = 8, p = 0.6)

# Plot forecast of burnout risk, tasks, and fatigue over 30 days
plot_burnout_forecast(result)
```

## Functions

### simulate_burnout()
Runs the burnout simulation and returns a data frame.

**Arguments:**
- `n_tasks`: Number of tasks at the beginning (>= 0)
- `p`: Productivity rate (between 0 and 1)
- `threshold`: Burnout threshold (default is 3)
- `days`: Number of days to simulate (default is 30)
- `reps`: Number of simulation repetitions (default is 1000)
- `task_arrival_rate`: Avg daily new tasks (default is 0.5)
- `seed`: Set seed for reproducibility (default is 123)

**Returns:** A data frame with:
- Day
- BurnoutRisk
- AvgPendingTasks
- Fatigue
- Summary_HighRiskDays
- Summary_PeakRiskDay
- Summary_MaxFatigue

### plot_burnout_forecast()
Plots a line graph of the burnout simulation results.

**Arguments:**
- `df`: The output from `simulate_burnout()`

**Returns:** A ggplot2 line chart showing changes in risk, fatigue, and task load.

## Testing

Make sure your tests expect all 7 columns in the result.

```r
test_that("simulate_burnout returns correct structure", {
  df <- simulate_burnout(n_tasks = 5, p = 0.5, threshold = 3, days = 10, reps = 100)

  expect_s3_class(df, "data.frame")
  expect_equal(ncol(df), 7)
  expect_true(all(c("Day", "BurnoutRisk", "AvgPendingTasks", "Fatigue",
                    "Summary_HighRiskDays", "Summary_PeakRiskDay", "Summary_MaxFatigue") %in% colnames(df)))
  expect_equal(nrow(df), 10)
})
```

## Purpose

We made this package to add a burnout prediction feature to a scheduling app built with Shiny. It also helped us practice building R packages with C++ using Rcpp.
