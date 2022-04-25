# crawl-linkedin.R --------------------------------------------------------
# The instructions to the crawler to scrape LinkedIn.
# 
# Have with “rselenium-chrome” as the working directory, so R can find the
# necessary input files.
# 
# Needs Docker Desktop installed, and both rselenium-base-functions.R and 
# linkedin-functions.R in the working directory. Also needs a keyring named 
# “usc” configured with a username/password set up for a LinkedIn account. For 
# more details on configuring a keyring, see the tutorial script 
# “rselenium-chrome/keyring/r-keyring-tutorial.R”
# 
# Outputs the following:
# - linkedin-results.csv
#
# If there are questions/comments, please contact Matt (mdlee@usc.edu).
# -------------------------------------------------------------------------

# Loading required packages
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("lubridate"))
suppressPackageStartupMessages(library("RSelenium"))
suppressPackageStartupMessages(library("getProxy"))
suppressPackageStartupMessages(library("keyring"))

# Loading wrapper functions
source("rselenium-base-functions.R")
source("linkedin-functions.R")

# Setting email to log into LinkeIn with; the password of this account should
# be stored in the "usc" keyring
email <- "testingtesting123yay@gmail.com"

# Unlocking keyring "usc"; input password from configuration of this keyring
keyring_unlock("usc")

# Loading query text
linkedin_search_query <- read.csv("inputs/linkedin-search-query.csv", stringsAsFactors = FALSE)

startSession()

# Getting profile links ---------------------------------------------------

links_list <- rep(as.list(as.character(NA)), nrow(linkedin_search_query))
linkedinLogin("testingtesting123yay@gmail.com")
i <- 1
while (!is_empty(i)) {
  
  i <- suppressWarnings(min(which(is.na(links_list))))
  
  if (i == Inf) {
    break
  }
  
  links <- tryCatch(
    expr = {
      linkedinGetProfileLinks(linkedin_search_query$to_search[i])
    },
    error = function(e) {
      resetContainer()
      Sys.sleep(5)
      linkedinLogin("testingtesting123yay@gmail.com")
      Sys.sleep(5)
    }
  )
  
  links_list[[i]] <- links
  Sys.sleep(1)
}

# For each row, take first link found as "url" for next search
first_link <- lapply(
  links_list,
  function(x) {
    x %>%
      head(1) %>%
      { if(is_empty(.)) NA else . }
  }
) %>%
  unlist

linkedin_search_query$url <- first_link

# Scraping Profiles -------------------------------------------------------

profile_data <- data.frame(
  url = unique(na.exclude(linkedin_search_query$url)),
  highest_degree = as.character(NA),
  degree_area = as.character(NA),
  stringsAsFactors = FALSE
)

i <- 1
while (!is_empty(i)) {
  
  i <- suppressWarnings(min(which(!rowSums(!is.na(profile_data[,-1])))))
  url <- profile_data$url[i]
  
  if (i == Inf) {
    break
  }
  
  profile <- tryCatch(
    expr = {
      linkedinGetProfileData(url)
    },
    error = function(e) {
      # Sometimes LinkedIn forces a crash (even if page works in manual search)
      # If that occurs, reset and log back in. Then fill row i's info with
      # blank strings (not NA), so loop will skip over once it continues.
      resetContainer()
      linkedinLogin("testingtesting123yay@gmail.com")
      data.frame(
        url = profile_url,
        highest_degree = "",
        degree_area = "",
        stringsAsFactors = FALSE
      )
    }
  )
  
  profile_data[i, c("highest_degree", "degree_area")] <- profile[1, c("highest_degree", "degree_area")]
  Sys.sleep(1)
}

# Final Results -----------------------------------------------------------

linkedin_results <- linkedin_search_query %>% left_join(profile_data, by = "url")
write.csv(linkedin_results, "linkedin-results.csv")
endSession()