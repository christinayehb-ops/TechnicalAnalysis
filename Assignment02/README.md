# BDA400 Assignment 2 - Technical Analysis using R (Preliminary Stage)

**Repository:** https://github.com/christinayehb-ops/TechnicalAnalysis  
**Course:** BDA400 - Data Science Tools and Techniques  
**Assignment:** 2 (5%)

## Contents

- `portfolio.txt`: five US-listed stock symbols, one per line.
- `00_install_packages.R`: installs/checks quantmod, TTR, xts and zoo.
- `01_stock_functions.R`: portfolio import, Yahoo Finance loading, statistics, data displays, and three charts for each ticker.
- `02_run_analysis.R`: executes the pipeline and exports all charts, CSV files and session information.
- `03_offline_tests.R`: synthetic-data validation tests (not real stock data).
- `Assignment02.Rproj`: RStudio project; open this first.
- `outputs/`: generated CSV, PNG and session metadata files, added after a successful RStudio run.
- `evidence/`: original installation, GitHub and output screenshots.
- `StudentName_BDA400_A02.docx`: Word report supplied in the downloadable ZIP; upload it here once completed with genuine evidence and student details.

## Install and run

1. Install R: https://cran.r-project.org/
2. Install RStudio: https://posit.co/downloads/
3. Open `Assignment02.Rproj` in RStudio.
4. Source `00_install_packages.R` and capture the console package checks.
5. Source `03_offline_tests.R`; confirm that all synthetic-data tests pass.
6. Source `02_run_analysis.R` while connected to the internet; Yahoo Finance access is needed.
7. Inspect `outputs/stock_statistics.csv`, the per-symbol CSVs and all generated PNGs.
8. Insert original screenshots E01–E12 into the downloadable Word report; fill in the cover-page details; rename it `FirstLast_BDA400_A02.docx`; upload the completed report and screenshots to this folder.

Command-line alternative:
```bash
cd Assignment02
Rscript 00_install_packages.R
Rscript 03_offline_tests.R
Rscript 02_run_analysis.R
```

## Methodology

Approximately one year of daily market observations is requested through `quantmod::getSymbols(src = "yahoo", auto.assign = FALSE)`. A separate regular R data frame is created for each of AAPL, MSFT, GOOGL, JPM, XOM. Adjusted close is preferred for statistics, falling back to close when absent. The metrics are mean, median, sample standard deviation, a uniquely repeated two-decimal mode (otherwise NA), and 20/50-observation simple moving averages calculated with TTR. Charts show price + SMAs, volume, daily-return distribution, and a portfolio mean/median comparison.

If Yahoo Finance fails for any ticker, the analysis stops rather than silently omitting data. The moving-average columns contain NA until enough observations exist. The synthetic unit test does not represent empirical market-data execution.

## Submission status

The scripts, portfolio and report text are prepared, but local R/RStudio installation, live market-data execution, original screenshots and final Word upload still require student verification. The Word report is not a substantiated final submission until those steps are completed.

## Official references

- https://www.r-project.org/
- https://posit.co/downloads/
- https://search.r-project.org/CRAN/refmans/quantmod/html/getSymbols.html
- https://search.r-project.org/CRAN/refmans/TTR/html/MovingAverages.html
- https://docs.github.com/en/repositories/creating-and-managing-repositories
