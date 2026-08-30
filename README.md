# BDA400 Assignment 6 – R Shiny Stock Portfolio Dashboard

**Student:** Christina Gebrekirstoes  
**Course:** BDA400 – Data Science Tools and Techniques  
**Assignment:** Assignment 6 – Technical Analysis using R, Visualization Phase  
**Repository:** TechnicalAnalysis

## Project Overview

This project is an interactive R Shiny technical-analysis dashboard for retrieving, visualizing, and analyzing historical stock-market data. Yahoo Finance is the primary data source, with Stooq available as an alternate source and automatic fallback if the preferred source cannot return data.

## Features

- Historical stock-data retrieval using `quantmod`
- Yahoo Finance primary data source with Stooq alternate/fallback support
- Daily, Weekly, and Monthly time frames
- User-controlled stock symbol and date range
- Line, Candlestick, and Area chart options
- Fast and Slow Simple Moving Averages (SMA) with customizable periods
- Relative Strength Index (RSI)
- Moving Average Convergence Divergence (MACD)
- Technical indicators that can be enabled or disabled dynamically
- Customizable trading rules using SMA crossover logic
- Optional RSI confirmation for Buy/Sell signals
- Optional MACD confirmation for Buy/Sell signals
- Buy, Sell, and Hold trading states
- Buy/Sell annotations on the stock chart
- Trading-signal summary table
- Dashboard metrics for source used, latest close, and latest trading state
- Validation and error handling for invalid symbols, invalid date ranges, insufficient history, and unavailable stock data

## Required R Packages

The application uses the following packages:

- `shiny`
- `ggplot2`
- `quantmod`
- `TTR`
- `gridExtra`

The application checks for missing packages and installs them automatically when necessary.

## Main Application File

`app.R`

The `app.R` file contains the complete Shiny user interface, server logic, stock-data retrieval and fallback workflow, time-frame conversion, technical-indicator calculations, chart rendering, trading-signal rules, validation, and error handling.

## Trading Logic

The dashboard calculates a Fast SMA and Slow SMA using user-selected periods.

- **Buy:** Fast SMA crosses above Slow SMA.
- **Sell:** Fast SMA crosses below Slow SMA.
- **Hold:** No new crossover event occurs.

Users may optionally require RSI and/or MACD confirmation before a crossover is treated as a Buy or Sell event.

## How to Run

1. Download or clone this repository.
2. Open the project folder in RStudio.
3. Open `app.R`.
4. Click **Run App**.
5. Enter or select a stock symbol and date range.
6. Select Daily, Weekly, or Monthly analysis.
7. Select Line, Candlestick, or Area chart type.
8. Configure the technical indicators and trading-rule parameters as desired.
9. Review the dashboard chart, RSI/MACD panels, trading annotations, and signal table.

## Assignment Deliverables

- `app.R` – complete R Shiny dashboard
- `README.md` – project documentation and setup instructions
- Public GitHub repository containing the assignment files

## Author

Christina Gebrekirstoes
