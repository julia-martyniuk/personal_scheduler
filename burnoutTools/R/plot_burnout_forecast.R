#' Plot Burnout Forecast
#'
#' @param df Dataframe from simulate_burnout()
#' @return A ggplot object
#' @export
plot_burnout_forecast <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = Day, y = BurnoutRisk)) +
    ggplot2::geom_line(color = "firebrick", size = 1.2) +
    ggplot2::labs(title = "Projected Burnout Risk Over Time",
                  x = "Day",
                  y = "Probability of Burnout") +
    ggplot2::theme_minimal()
}
