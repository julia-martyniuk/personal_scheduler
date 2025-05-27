#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame simulate_burnout_cpp(int n_tasks, double p, int threshold, int days, int reps, double task_arrival_rate = 0.5) {
  // Initialize vectors to hold aggregated results across all repetitions
  std::vector<double> risk(days, 0.0);
  std::vector<double> avg_pending(days, 0.0);
  std::vector<double> fatigue(days, 0.0);
  std::vector<int> over_threshold_count(days, 0);

  // Trackers for summary statistics
  int total_high_risk_days = 0;
  double max_fatigue = 0.0;
  int peak_day = 0;
  double peak_risk = 0.0;

  // Set RNG scope for Rcpp
  Rcpp::RNGScope rngScope;

  for (int r = 0; r < reps; ++r) {
    int pending = n_tasks;
    double productivity = p;

    std::vector<double> risk_this_run(days, 0.0);
    std::vector<double> fatigue_this_run(days, 0.0);

    for (int d = 0; d < days; ++d) {
      // Simulate task arrivals using Poisson distribution
      int new_tasks = R::rpois(task_arrival_rate);
      pending += new_tasks;

      // Adjust productivity based on previous day's overload status
      if (d > 0) {
        if (over_threshold_count[d - 1] > 0) {
          productivity *= 0.98;  // productivity decreases (fatigue)
        } else {
          productivity *= 1.01;  // small recovery
        }
      }

      // Limit productivity to [0.1, 1.0]
      productivity = std::min(1.0, std::max(0.1, productivity));

      // Simulate task completions (binomial draw)
      int completed = R::rbinom(pending, productivity);
      pending = std::max(0, pending - completed);

      // Accumulate values for this day
      avg_pending[d] += pending;

      // Burnout risk increases with backlog (logistic growth)
      double risk_today = 1.0 / (1.0 + std::exp(-0.8 * (pending - threshold)));
      risk[d] += risk_today;
      risk_this_run[d] = risk_today;

      // Fatigue is calculated from productivity loss
      double fatigue_today = (1.0 - productivity);
      fatigue[d] += fatigue_today;
      fatigue_this_run[d] = fatigue_today;

      // Check if workload exceeded burnout threshold
      if (pending > threshold) {
        over_threshold_count[d]++;
      }
    }

    // Update summary statistics for this run
    for (int d = 0; d < days; ++d) {
      if (risk_this_run[d] > 0.7) total_high_risk_days++;
      if (risk_this_run[d] > peak_risk) {
        peak_risk = risk_this_run[d];
        peak_day = d + 1;
      }
      if (fatigue_this_run[d] > max_fatigue) {
        max_fatigue = fatigue_this_run[d];
      }
    }
  }

  // Average results across all simulations
  for (int d = 0; d < days; ++d) {
    risk[d] /= reps;
    avg_pending[d] /= reps;
    fatigue[d] /= reps;
  }

  // Return results as an R data frame
  return DataFrame::create(
    Named("Day") = seq(1, days),
    Named("BurnoutRisk") = risk,
    Named("AvgPendingTasks") = avg_pending,
    Named("Fatigue") = fatigue,
    Named("Summary_HighRiskDays") = total_high_risk_days / double(reps),
    Named("Summary_PeakRiskDay") = peak_day,
    Named("Summary_MaxFatigue") = max_fatigue
  );
}
