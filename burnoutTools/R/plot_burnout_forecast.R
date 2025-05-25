#' Plot Burnout Forecast
#'
#' Produces a line plot of simulated burnout risk over time.
#'
#' @param df A data frame returned by `simulate_burnout()`, with `Day` and `BurnoutRisk` columns.
#'
#' @return A ggplot2 object.
#' @export
#' @importFrom ggplot2 ggplot aes geom_line labs theme_minimal
plot_burnout_forecast <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = Day, y = BurnoutRisk)) +
    ggplot2::geom_line(color = "firebrick", size = 1.2) +
    ggplot2::labs(
      title = "Projected Burnout Risk Over Time",
      x = "Day",
      y = "Probability of Burnout"
    ) +
    ggplot2::theme_minimal()
}
