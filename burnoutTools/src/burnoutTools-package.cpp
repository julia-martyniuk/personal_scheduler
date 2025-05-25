#include <Rcpp.h>
using namespace Rcpp;

#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame simulate_burnout_cpp(int n_tasks, double p, int threshold, int days, int reps) {
  std::vector<double> risk(days, 0.0);
  
  for (int r = 0; r < reps; ++r) {
    int pending = n_tasks;
    for (int d = 0; d < days; ++d) {
      int completed = 0;
      for (int t = 0; t < pending; ++t) {
        if (R::runif(0, 1) < p) {
          ++completed;
        }
      }
      pending = std::max(0, pending - completed);
      if (pending > threshold) {
        risk[d] += 1.0;
      }
    }
  }
  
  for (int d = 0; d < days; ++d) {
    risk[d] /= reps;
  }
  
  IntegerVector day_seq = seq(1, days);
  return DataFrame::create(Named("Day") = day_seq,
                           Named("BurnoutRisk") = risk);
}
