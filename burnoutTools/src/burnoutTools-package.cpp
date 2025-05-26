#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame simulate_burnout_cpp(int n_tasks, double p, int threshold, int days, int reps) {
  // Vectors to accumulate daily burnout risk and average pending tasks over all simulations
  std::vector<double> risk(days, 0.0);
  std::vector<double> avg_pending(days, 0.0);

  // Initialize RNG scope to ensure proper random number generation in R context
  Rcpp::RNGScope rngScope;

  // Run 'reps' independent simulations
  for (int r = 0; r < reps; ++r) {
    int pending = n_tasks;  // Start with all tasks pending at day 0

    // Simulate day-by-day task completion and burnout risk accumulation
    for (int d = 0; d < days; ++d) {
      // Number of completed tasks follows a binomial distribution: completed ~ Binomial(pending, p)
      int completed = R::rbinom(pending, p);

      // Update remaining pending tasks, ensuring non-negative
      pending = std::max(0, pending - completed);

      // If pending tasks exceed threshold, increment burnout risk count for this day
      if (pending > threshold) {
        risk[d] += 1.0;
      }

      // Accumulate pending tasks for averaging later
      avg_pending[d] += pending;
    }
  }

  // Average the results over the number of repetitions
  for (int d = 0; d < days; ++d) {
    risk[d] /= reps;
    avg_pending[d] /= reps;
  }

  // Return a data frame with daily values of burnout risk and average pending tasks
  return DataFrame::create(
    Named("Day") = seq(1, days),
    Named("BurnoutRisk") = risk,
    Named("AvgPendingTasks") = avg_pending
  );
}
