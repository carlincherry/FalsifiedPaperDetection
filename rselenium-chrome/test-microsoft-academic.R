# test-microsoft-academic.R -----------------------------------------------
# Tests Microsoft Academic scraping. Navigates to the site, searches for 
# Chris Mattmann and a few other authors, and views their information in 
# a table.
# 
# Needs Docker Desktop installed and both rselenium-base-functions.R and 
# microsoft-academic-functions.R in the working directory.
# -------------------------------------------------------------------------

# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

# Loading setup functions
source("rselenium-base-functions.R")
source("microsoft-academic-functions.R")

tryCatch(
  expr = {
    startSession()
    test <- mapply(
      function(x, y) {
        microsoftSearchAuthor(x, y)
      },
      x = c("Chris Mattmann",
            "Ned Freed",
            "Nathaniel Borenstein"),
      y = c("A vision for data science", 
            " ", 
            " "),
      SIMPLIFY = FALSE
    ) %>%
      map(function(x) {x}) %>%
      reduce(bind_rows)
  },
  warning = function(w) {
    w
  },
  error = function(e) {
    e
  },
  finally = {
    endSession()
    View(test)
  }
)
