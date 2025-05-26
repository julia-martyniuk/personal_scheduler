# burnoutTools

`burnoutTools` is an R package developed as part of a group project for the **Advanced Programming in R** course. It simulates and visualizes burnout risk based on task completion behavior. The simulation is written in C++ via Rcpp, and results are visualized using ggplot2.

---

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

* `simulate_burnout()` – runs the burnout simulation
* `plot_burnout_forecast()` – creates a simple plot with ggplot2

## Purpose

This package was created to extend a Shiny-based personal scheduler app by adding a burnout forecast feature. It was also a way for us to apply what I learned about writing R packages and integrating C++ with R through Rcpp.

