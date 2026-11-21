# BDA400 - Assignment 2 | Setup: install the packages used in this project
# Execute this file once in RStudio (or when a package is missing).

required_packages <- c("quantmod", "TTR", "xts", "zoo")
missing_packages <- setdiff(required_packages, rownames(installed.packages()))

if (length(missing_packages) > 0L) {
  message("Installing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

for (package_name in required_packages) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop("Unable to load package '", package_name,
         "'. Check the installation log and try again.")
  }
  message(package_name, " version ",
          as.character(utils::packageVersion(package_name)), " is available.")
}

message("Package setup checks passed. Next, run 02_run_analysis.R.")
