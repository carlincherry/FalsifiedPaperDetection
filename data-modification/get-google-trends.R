# get-google-trends.R -----------------------------------------------------
# Part of our auxiliary datasets. Uses the gtrendsR package to query the Google
# Trends API. Runs queries with information from the Bik dataset and compiles
# results for export.
# 
# Needs the following file in the working directory:
# - google-trends-query.json
# 
# Outputs the following:
# - google-trends-results.csv
#
# If there are questions/comments, please contact Matt (mdlee@usc.edu).
# -------------------------------------------------------------------------

# Loading required packages
library(tidyverse)
library(gtrendsR)
library(jsonlite)

# Loading input for querying Google Trends
google_trends_query <- read_json("google-trends-query.json", simplifyVector = TRUE)

# Function to Get Google Trends Data --------------------------------------

getGoogleTrends <- function(first_author, title, year, month, top_topics) {
  # A function to take in information from a given row of Bik's dataset, run
  # a few Google Trends queries, and return the interest values from web,
  # images, and youtube.
  
  forceInteger <- function(x) {
    # Low search volume results in "<1" (which makes a character vector)
    # This is a way to force those to integer, default 0
    if (class(x) == "character") {
      x[x == "<1"] <- "0"
      as.integer(x)
    } else {
      x
    }
  }
  
  getScores <- function(df) {
    # Given a data frame from the output of gtrends:
    # Take each date, average the interest value/hits across each time series
    # 4 time series to average (biology + 3 "top topics")
    df %>%
      mutate_at(vars("hits"), forceInteger) %>%
      group_by(date) %>%
      summarize(hits = mean(hits))
  }
  
  month <- coalesce(month, "January")
  target_date <- as.Date(paste(year, month, "01", sep = "-"), "%Y-%B-%d")
  if (target_date <= as.Date("2004-01-01")) {
    target_date <- as.Date("2004-01-01")
  }
  
  # Make a query of keywords--biology always included as a baseline for comparison
  # top_topics is a list of 3 topics relevant to the author, taken from Microsoft Academic
  query <- c("biology", top_topics[[1]])
  
  # Running Google Trends queries
  web <- gtrends(query, time = "all", gprop = "web", onlyInterest = TRUE)$interest_over_time
  images <- gtrends(query, time = "all", gprop = "images", onlyInterest = TRUE)$interest_over_time
  youtube <- gtrends(query, time = "all", gprop = "youtube", onlyInterest = TRUE)$interest_over_time
  
  # Obtaining scores
  web <- web %>%
    getScores %>%
    rename(web = hits)
  images <- images %>%
    getScores %>%
    rename(images = hits)
  youtube <- youtube %>%
    getScores %>%
    rename(youtube = hits)
  all <- list(web, images, youtube) %>%
    map(function(x) {x}) %>%
    reduce(merge) %>%
    filter(date == target_date)
  
  # Cleaning output
  output <- data.frame(
    first_author = first_author,
    title = title,
    web_interest = all$web[1],
    images_interest = all$images[1],
    youtube_interest = all$youtube[1],
    stringsAsFactors = FALSE
  )
}

# Getting the Data --------------------------------------------------------

# Initializing results
google_trends_results <- data.frame(
  first_author = google_trends_query$first_author,
  title = google_trends_query$title,
  web_interest = as.numeric(NA),
  images_interest = as.numeric(NA),
  youtube_interest = as.numeric(NA)
)

# Loop through each row of Bik data
# API has a daily (roughly in the 100's)
# If messages start popping up, manually break and try again later
while (i != Inf) {
  i <- suppressWarnings(min(which(!rowSums(!is.na(google_trends_results[,c(-1,-2)])))))
  tryCatch(
    expr = {
      temp <- getGoogleTrends(google_trends_query$first_author[i],
                              google_trends_query$title[i],
                              google_trends_query$year[i],
                              google_trends_query$month[i],
                              google_trends_query$top_topics[i])
      google_trends_results[i,] <- temp
    },
    error = function(e) {
      message('Something went wrong...')
      Sys.sleep(1)
    }
  )
}

write.csv(google_trends_results, "google-trends-results.csv", row.names = FALSE)

# Attempted vectorized function...fails
# Overloads API perhaps
#
# google_trends_results <- mapply(
#   getGoogleTrends,
#   first_author = google_trends_query$first_author,
#   title = google_trends_query$title,
#   year = google_trends_query$year,
#   month = google_trends_query$month,
#   top_topics = google_trends_query$top_topics,
#   SIMPLIFY = FALSE
# ) %>%
#   map(function(x) {x}) %>%
#   reduce(bind_rows)