#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame simulate_burnout_cpp(int n_tasks, double p, int threshold, int days, int reps) {
  std::vector<double> burnout_prob(days, 0.0);

  for (int r = 0; r < reps; ++r) {
    int pending_tasks = n_tasks;

    for (int d = 0; d < days; ++d) {
      int completed_tasks = 0;

      // Bernoulli trial for each task
      for (int t = 0; t < pending_tasks; ++t) {
        if (R::runif(0.0, 1.0) < p) {
          completed_tasks++;
        }
      }

      pending_tasks = std::max(0, pending_tasks - completed_tasks);

      if (pending_tasks > threshold) {
        burnout_prob[d] += 1.0;
      }
    }
  }

  // Normalize to probability
  for (double &val : burnout_prob) {
    val /= reps;
  }

  return DataFrame::create(
    Named("Day") = seq(1, days),
    Named("BurnoutRisk") = burnout_prob
  );
}
