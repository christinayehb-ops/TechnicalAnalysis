# BDA400 - Assignment 2 | Main analysis and output generator
# Open Assignment02.Rproj first, then Source this file in RStudio.
# Or from a terminal: cd Assignment02 && Rscript 02_run_analysis.R

required <- c("quantmod", "TTR", "xts", "zoo")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0L) {
  stop("Missing R packages: ", paste(missing, collapse = ", "),
       ". Source 00_install_packages.R and retry.")
}

# When executed with Rscript from elsewhere, resolve paths relative to this script.
command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
if (length(file_arg) > 0L) {
  project_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1L])))
} else {
  project_dir <- getwd()
}
if (!file.exists(file.path(project_dir, "portfolio.txt"))) {
  stop("Open Assignment02.Rproj first so that the working directory contains portfolio.txt.")
}
source(file.path(project_dir, "01_stock_functions.R"), local = FALSE)
output_dir <- file.path(project_dir, "outputs")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Yahoo's end date is exclusive. The range below covers approximately one year.
start_date <- Sys.Date() - 365
end_date <- Sys.Date() + 1
portfolio_path <- file.path(project_dir, "portfolio.txt")
cat("Data window: ", as.character(start_date), " through ",
    as.character(Sys.Date()), " (subject to available trading days)\n", sep = "")

stock_frames <- load_stock_data(portfolio_path, from = start_date, to = end_date)
statistics_by_symbol <- list()
processed_frames <- list()

for (symbol in names(stock_frames)) {
  result <- calculate_statistics(stock_frames[[symbol]],
                                 short_window = 20L, long_window = 50L)
  processed_frames[[symbol]] <- result$data
  statistics_by_symbol[[symbol]] <- result$summary
  display_stock_data(result$data, result$summary)
  utils::write.csv(result$data, file.path(output_dir, paste0(symbol, "_daily_data.csv")),
                   row.names = FALSE, na = "")
  plot_stock_data(result$data, symbol, output_dir)
}

summary_table <- do.call(rbind, statistics_by_symbol)
rownames(summary_table) <- NULL
utils::write.csv(summary_table, file.path(output_dir, "stock_statistics.csv"),
                 row.names = FALSE, na = "")

# Multi-stock comparison (prices are per share and should not be compared as returns).
grDevices::png(file.path(output_dir, "portfolio_mean_vs_median.png"),
               width = 1300, height = 760, res = 125)
tryCatch({
  comparison <- rbind(Mean = summary_table$Mean, Median = summary_table$Median)
  colnames(comparison) <- summary_table$Symbol
  graphics::barplot(comparison, beside = TRUE, col = c("#153D64", "#61A39C"),
                    main = "Portfolio - descriptive closing-price statistics",
                    ylab = "Mean / median price (USD)", xlab = "Stock symbol")
  graphics::legend("topright", legend = rownames(comparison),
                   fill = c("#153D64", "#61A39C"), bty = "n")
}, finally = grDevices::dev.off())

writeLines(capture.output(sessionInfo()),
           con = file.path(output_dir, "session_info.txt"))
cat("\nAnalysis completed for ", length(stock_frames), " symbols.\n", sep = "")
cat("Summary saved to: ", file.path(output_dir, "stock_statistics.csv"), "\n", sep = "")
cat("Charts, data frames, and session metadata saved in outputs/.\n")
