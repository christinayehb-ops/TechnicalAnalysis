# BDA400 - Assignment 2 | Deterministic checks using invented test data
# This is a UNIT TEST only. The synthetic values are not market observations.
# Requires TTR but DOES NOT access Yahoo Finance or the internet.

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
project_dir <- if (length(file_arg) > 0L) {
  dirname(normalizePath(sub("^--file=", "", file_arg[1L])))
} else {
  getwd()
}
source(file.path(project_dir, "01_stock_functions.R"))

prices <- c(rep(100, 10), 101:150) # 60 test observations; unique mode is 100
sample_frame <- data.frame(
  Symbol = rep("TEST", length(prices)),
  Date = as.Date("2025-01-01") + seq_along(prices) - 1L,
  Open = prices, High = prices + 1, Low = prices - 1,
  Close = prices, Volume = rep(1000, length(prices)),
  Adjusted = prices, stringsAsFactors = FALSE
)
result <- calculate_statistics(sample_frame, short_window = 20L,
                               long_window = 50L)
stats_row <- result$summary
stopifnot(
  nrow(result$data) == 60L,
  stats_row$Observations == 60L,
  isTRUE(all.equal(stats_row$Mean, mean(prices))),
  isTRUE(all.equal(stats_row$Median, stats::median(prices))),
  isTRUE(all.equal(stats_row$StdDev, stats::sd(prices))),
  stats_row$Mode == 100,
  isTRUE(all.equal(result$data$SMA20[20L], mean(prices[1:20]))),
  isTRUE(all.equal(result$data$SMA50[50L], mean(prices[1:50]))),
  all(is.na(result$data$SMA20[1:19])),
  all(is.na(result$data$SMA50[1:49])),
  is.na(calculate_mode(1:5)),
  is.na(calculate_mode(c(1, 1, 2, 2)))
)
cat("All synthetic-data unit tests passed.\n")
