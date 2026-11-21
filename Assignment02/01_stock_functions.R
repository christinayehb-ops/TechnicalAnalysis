# BDA400 - Assignment 2 | Reusable stock data and statistics utilities
# Data source: Yahoo Finance via quantmod::getSymbols().
# Statistical unit: daily adjusted closing price where available, otherwise close.

read_portfolio <- function(file = "portfolio.txt") {
  if (!file.exists(file)) stop("Portfolio file not found: ", file)
  lines <- trimws(readLines(file, warn = FALSE, encoding = "UTF-8"))
  lines <- lines[nzchar(lines) & !grepl("^#", lines)]
  symbols <- unique(toupper(lines))
  if (length(symbols) == 0L) stop("portfolio.txt contains no stock symbols.")
  # Yahoo symbols may contain letters, numbers, dots, hyphens, and carets.
  if (any(!grepl("^[A-Z0-9.^-]+$", symbols))) {
    stop("Invalid characters in portfolio symbol(s): ",
         paste(symbols[!grepl("^[A-Z0-9.^-]+$", symbols)], collapse = ", "))
  }
  symbols
}

load_stock_data <- function(portfolio_file = "portfolio.txt",
                            from = Sys.Date() - 365,
                            to = Sys.Date() + 1) {
  if (!requireNamespace("quantmod", quietly = TRUE) ||
      !requireNamespace("zoo", quietly = TRUE)) {
    stop("Required packages are missing. Run 00_install_packages.R first.")
  }
  from <- as.Date(from)
  to <- as.Date(to)
  if (is.na(from) || is.na(to) || from >= to) {
    stop("'from' and 'to' must be valid dates, with from < to.")
  }
  symbols <- read_portfolio(portfolio_file)
  frames <- list()
  failures <- character(0)

  for (symbol in symbols) {
    message("Retrieving ", symbol, " from Yahoo Finance ...")
    result <- tryCatch({
      prices_xts <- quantmod::getSymbols(
        Symbols = symbol, src = "yahoo", from = from, to = to,
        auto.assign = FALSE, warnings = FALSE
      )
      if (NROW(prices_xts) == 0L) stop("No price observations returned.")

      adjusted <- tryCatch(as.numeric(quantmod::Ad(prices_xts)),
                           error = function(e) rep(NA_real_, NROW(prices_xts)))
      if (length(adjusted) != NROW(prices_xts)) {
        adjusted <- rep(NA_real_, NROW(prices_xts))
      }
      frame <- data.frame(
        Symbol = rep(symbol, NROW(prices_xts)),
        Date = as.Date(zoo::index(prices_xts)),
        Open = as.numeric(quantmod::Op(prices_xts)),
        High = as.numeric(quantmod::Hi(prices_xts)),
        Low = as.numeric(quantmod::Lo(prices_xts)),
        Close = as.numeric(quantmod::Cl(prices_xts)),
        Volume = as.numeric(quantmod::Vo(prices_xts)),
        Adjusted = adjusted,
        stringsAsFactors = FALSE
      )
      frame <- frame[!is.na(frame$Date) & is.finite(frame$Close), , drop = FALSE]
      frame <- frame[order(frame$Date), , drop = FALSE]
      rownames(frame) <- NULL
      if (nrow(frame) == 0L) stop("No usable closing-price rows returned.")
      frame
    }, error = function(e) {
      failures <<- c(failures, paste0(symbol, ": ", conditionMessage(e)))
      NULL
    })

    if (!is.null(result)) frames[[symbol]] <- result
  }

  if (length(failures) > 0L) {
    stop("Unable to retrieve ALL portfolio symbols. Retry with internet access, ",
         "confirm the ticker codes, and check the Yahoo Finance service.\n",
         paste(failures, collapse = "\n"))
  }
  # Each named element is a separate ordinary R data frame for one ticker.
  frames
}

calculate_mode <- function(x) {
  # A single mode is reported only if exactly one 2-decimal price repeats most.
  # This operational definition avoids a spurious mode for all-unique prices.
  x <- round(as.numeric(x[is.finite(x)]), digits = 2L)
  if (length(x) == 0L) return(NA_real_)
  frequencies <- table(x)
  max_frequency <- max(frequencies)
  if (max_frequency < 2L || sum(frequencies == max_frequency) != 1L) {
    return(NA_real_)
  }
  as.numeric(names(frequencies)[which.max(frequencies)])
}

safe_sma <- function(x, n) {
  if (!requireNamespace("TTR", quietly = TRUE)) {
    stop("The TTR package is required. Run 00_install_packages.R first.")
  }
  if (length(x) < n) return(rep(NA_real_, length(x)))
  as.numeric(TTR::SMA(x, n = n))
}

calculate_statistics <- function(stock_frame, short_window = 20L,
                                 long_window = 50L) {
  required_columns <- c("Symbol", "Date", "Close", "Adjusted", "Volume")
  if (!is.data.frame(stock_frame) ||
      !all(required_columns %in% names(stock_frame))) {
    stop("stock_frame must be a data frame with columns: ",
         paste(required_columns, collapse = ", "))
  }
  if (nrow(stock_frame) == 0L) stop("Cannot summarize an empty stock frame.")
  if (!is.numeric(short_window) || !is.numeric(long_window) ||
      length(short_window) != 1L || length(long_window) != 1L ||
      is.na(short_window) || is.na(long_window) ||
      short_window < 1 || long_window < short_window ||
      short_window != floor(short_window) || long_window != floor(long_window)) {
    stop("Moving-average windows must be positive integers (short <= long).")
  }
  stock_frame <- stock_frame[order(stock_frame$Date), , drop = FALSE]
  close_price <- as.numeric(stock_frame$Close)
  adjusted_price <- as.numeric(stock_frame$Adjusted)
  price <- ifelse(is.finite(adjusted_price), adjusted_price, close_price)
  if (any(!is.finite(price))) stop("Price series contains missing or invalid observations.")
  short_sma <- safe_sma(price, as.integer(short_window))
  long_sma <- safe_sma(price, as.integer(long_window))
  daily_return <- c(NA_real_, 100 * diff(price) / head(price, -1L))

  stock_frame$AnalysisPrice <- price
  stock_frame$SMA20 <- short_sma
  stock_frame$SMA50 <- long_sma
  stock_frame$DailyReturnPct <- daily_return
  n <- nrow(stock_frame)
  summary_frame <- data.frame(
    Symbol = as.character(stock_frame$Symbol[n]),
    FirstDate = min(stock_frame$Date),
    LastDate = max(stock_frame$Date),
    Observations = n,
    LatestPrice = price[n],
    Mean = mean(price),
    Mode = calculate_mode(price),
    Median = stats::median(price),
    StdDev = if (n >= 2L) stats::sd(price) else NA_real_,
    LatestSMA20 = short_sma[n],
    LatestSMA50 = long_sma[n],
    stringsAsFactors = FALSE
  )
  list(data = stock_frame, summary = summary_frame)
}

display_stock_data <- function(stock_frame, summary_frame, n_rows = 5L) {
  symbol <- as.character(summary_frame$Symbol[1L])
  cat("\n", strrep("=", 65L), "\n", sep = "")
  cat("Stock: ", symbol, " | First and last ", n_rows, " observations\n", sep = "")
  print(utils::head(stock_frame, n_rows), row.names = FALSE)
  cat("\nLast observations:\n")
  print(utils::tail(stock_frame, n_rows), row.names = FALSE)
  cat("\nCalculated descriptive statistics:\n")
  print(summary_frame, row.names = FALSE, digits = 5L)
  if (is.na(summary_frame$Mode[1L])) {
    cat("Mode: NA (no single repeated most-common price to 2 decimals).\n")
  }
  invisible(NULL)
}

plot_stock_data <- function(stock_frame, symbol, output_dir = "outputs") {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  dates <- stock_frame$Date
  price <- stock_frame$AnalysisPrice
  file_prefix <- gsub("[^A-Za-z0-9_-]", "_", symbol)

  # Figure 1: daily analysis price plus 20-day and 50-day simple averages.
  grDevices::png(file.path(output_dir, paste0(file_prefix, "_price_sma.png")),
                 width = 1300, height = 760, res = 125)
  tryCatch({
    graphics::plot(dates, price, type = "l", col = "#153D64", lwd = 1.7,
                   main = paste(symbol, "- daily price and moving averages"),
                   xlab = "Trading date", ylab = "Price (USD)")
    graphics::grid(col = "#E1E5EA")
    graphics::lines(dates, stock_frame$SMA20, col = "#E39B32", lwd = 2)
    graphics::lines(dates, stock_frame$SMA50, col = "#33927E", lwd = 2)
    graphics::legend("topleft", bty = "n", lwd = 2,
                     col = c("#153D64", "#E39B32", "#33927E"),
                     legend = c("Analysis price", "SMA (20)", "SMA (50)"))
  }, finally = grDevices::dev.off())

  # Figure 2: daily traded share volume (a separate measure, not a price).
  grDevices::png(file.path(output_dir, paste0(file_prefix, "_volume.png")),
                 width = 1300, height = 760, res = 125)
  tryCatch({
    graphics::plot(dates, stock_frame$Volume / 1e6, type = "h",
                   col = "#6393B8", lwd = 2,
                   main = paste(symbol, "- daily trading volume"),
                   xlab = "Trading date", ylab = "Shares traded (millions)")
    graphics::grid(col = "#E1E5EA")
  }, finally = grDevices::dev.off())

  # Figure 3: daily percentage price returns.
  returns <- stock_frame$DailyReturnPct[is.finite(stock_frame$DailyReturnPct)]
  if (length(returns) > 1L) {
    grDevices::png(file.path(output_dir, paste0(file_prefix, "_returns.png")),
                   width = 1300, height = 760, res = 125)
    tryCatch({
      graphics::hist(returns, col = "#8AABD2", border = "white",
                     breaks = "FD", main = paste(symbol, "- daily returns"),
                     xlab = "Daily price change (%)")
      graphics::abline(v = 0, col = "#A74642", lty = 2, lwd = 2)
    }, finally = grDevices::dev.off())
  }
  invisible(NULL)
}
