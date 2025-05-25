# burnoutTools

This R package was created as part of a final project for the Advanced Programming in R course. It provides a tool to simulate and visualize burnout risk based on task completion behavior. The simulation is implemented in C++ using Rcpp, and the output is visualized using ggplot2.

## Features

* Simulates the probability of burnout over time using a Monte Carlo method
* Uses C++ for fast computation via Rcpp
* Includes a simple ggplot2-based function to plot the forecast
* Designed for integration into Shiny applications

## Installation

This package is not on CRAN. To install it locally:

```r
devtools::install("path/to/burnoutTools")
```

## Example

```r
library(burnoutTools)

# Simulate burnout with 8 tasks and 60% daily completion chance
df <- simulate_burnout(n_tasks = 8, p = 0.6)

# Plot the forecast
plot_burnout_forecast(df)
```

## Functions

* `simulate_burnout()` – Runs the burnout simulation
* `plot_burnout_forecast()` – Visualizes the result using ggplot2

## Purpose

This package was developed to extend the functionality of a Shiny-based scheduler application by adding a burnout forecasting feature. It demonstrates integration of C++ with R through Rcpp and packaging tools learned in the course.

## Author

Tseeltuul Erdenebat
University of Warsaw
[tseeleee.bay@gmail.com](mailto:tseeleee.bay@gmail.com)
