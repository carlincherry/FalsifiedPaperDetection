# test-linkedin.R ---------------------------------------------------------
# Tests LinkedIn scraping. Logs in using a test account 
# (testingtesting123yay@gmail.com), searches for Chris Mattmann, navigates 
# to his profile, and pulls some information.
# 
# Needs Docker Desktop installed and both rselenium-base-functions.R and 
# linkedin-functions.R in the working directory.
#
# Also needs a keyring named "usc" set up with password to a "linkedin" service.
# For more information on configuring the keyring, see the tutorial script
# rselenium-chrome/keyring/r-keyring-tutorial.R
#
# Note 03/05/2020: this used to work on "Chris Mattmann" and appropriately
# returned the professor. Now noticing that it returns the spoof profile's
# own information. Knowing LinkedIn, we suspect it changed the structure of
# the elements slightly. If we wanted to revive the LinkedIn functionality of
# our crawler, we would have to revisit the code, or possibly have it filter 
# out its own name (student test) from the results before pursuing a link.
# -------------------------------------------------------------------------

# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

# Loading setup functions
source("rselenium-base-functions.R")
source("linkedin-functions.R")

# Unlock keyring "usc"
keyring_unlock(keyring = "usc")

tryCatch(
  expr = {
    startSession()
    linkedinLogin("testingtesting123yay@gmail.com")
    test_links <- linkedinGetProfileLinks("Chris Mattmann")
    test <- linkedinGetProfileData(test_links[1])
  },
  warning = function(w) {
    w
  },
  error = function(e) {
    e
  },
  finally = {
    endSession()
    message('Found the following profile links; scraped the first one')
    print(test_links)
    View(test)
  }
)