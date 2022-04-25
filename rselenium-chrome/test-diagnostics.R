# test-diagnostics.R ------------------------------------------------------
# Tests basic crawler operations. Starts up a browser, navigates to Google, 
# and takes a screenshot. Restarts session and repeats. Switches browser to 
# Firefox, then back to Chrome.
# 
# Needs Docker Desktop installed and rselenium-base-functions.R run in the 
# working directory.
# -------------------------------------------------------------------------

# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

# Loading setup functions
source("rselenium-base-functions.R")

tryCatch(
  expr = {
    startSession()
    remDr$navigate("https://www.google.com")
    remDr$screenshot(display = TRUE)
    resetContainer()
    remDr$navigate("https://www.google.com")
    remDr$screenshot(display = TRUE)
    switchBrowser()
    remDr$navigate("https://www.google.com")
    remDr$screenshot(display = TRUE)
    switchBrowser()
    remDr$navigate("https://www.google.com")
    remDr$screenshot(display = TRUE)
  },
  warning = function(w) {
    w
  },
  error = function(e) {
    e
  },
  finally = {
    endSession()
  }
)
