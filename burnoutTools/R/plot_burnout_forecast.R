#' Plot burnout forecast
#'
#' This version shows Burnout Risk, Task Load, and Fatigue together
#' with a highlighted burnout risk zone.
#'
#' @param df Data frame returned by simulate_burnout()
#' @return A ggplot line chart showing how workload, stress, and fatigue evolve.
#' @export
plot_burnout_forecast <- function(df) {
  # Reshape data for long-format plot
  df_long <- tidyr::pivot_longer(
    df,
    cols = c("BurnoutRisk", "AvgPendingTasks", "Fatigue"),
    names_to = "Metric",
    values_to = "Value"
  )

  # Create the plot
  ggplot2::ggplot(df_long, ggplot2::aes(x = Day, y = Value, color = Metric)) +
    # Optional: light highlight for high-risk zone (only for BurnoutRisk)
    ggplot2::geom_rect(
      data = NULL,
      aes(xmin = -Inf, xmax = Inf, ymin = 0.7, ymax = Inf),
      inherit.aes = FALSE,
      fill = "mistyrose",
      alpha = 0.3
    ) +
    ggplot2::geom_line(size = 1.2) +
    ggplot2::scale_color_manual(values = c(
      "BurnoutRisk" = "#c0392b",       # muted red
      "AvgPendingTasks" = "#2980b9",   # muted blue
      "Fatigue" = "#e67e22"            # orange
    )) +
    ggplot2::labs(
      title = "Burnout Simulation Forecast",
      subtitle = "Highlighted area shows elevated burnout risk (above 0.7)",
      x = "Day",
      y = "Level / Count",
      color = "Metric"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "top",
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 10, color = "gray40")
    )
}
