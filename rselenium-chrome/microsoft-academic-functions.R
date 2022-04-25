# microsoft-academic-functions.R ------------------------------------------
# Part of our web crawler. Adds functions to the environment for scraping 
# Microsoft Academic.
# 
# Needs Docker Desktop installed. No input.
# 
# Outputs nothing.
#
# If there are questions/comments, please contact Matt (mdlee@usc.edu).
# -------------------------------------------------------------------------

# Loading required packages
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("lubridate"))
suppressPackageStartupMessages(library("RSelenium"))
suppressPackageStartupMessages(library("getProxy"))

microsoftSearchAuthor <- function(author, paper = "") {
  message(paste0('Starting search for ', author, ' + ', substring(paper, 0, 30), '...'))
  # Initialize author information
  author_info <- data.frame(
    first_author = author,
    affiliation = as.character(NA),
    publications = as.character(NA),
    citations = as.numeric(NA),
    year_start = as.numeric(NA),
    year_end = as.numeric(NA),
    top_topics = as.character(NA),
    publication_types = as.character(NA),
    top_authors = as.character(NA),
    top_journals = as.character(NA),
    top_institutions = as.character(NA),
    top_conferences = as.character(NA),
    stringsAsFactors = FALSE
  )
  
  # If not already on the Microsoft Academic page, navigate there and wait for header image
  if (unlist(remDr$getCurrentUrl()) != "https://academic.microsoft.com/home") {
    remDr$navigate("https://academic.microsoft.com/home")
  }
  webElem <- findElementCustom(using = "css selector", value = ".top", attempts = 20)
  remDr$screenshot(display = TRUE)
  
  # Find search box and enter author + paper
  webElem <- findElementCustom(using = "xpath", value = "/html/body/div/div/div/router-view/div/div[1]/div[2]/div/ma-suggestion-control/div/div[1]/input")
  webElem$clearElement()
  webElem$clickElement()
  webElem$sendKeysToElement(list(paste(author, paper)))
  webElem$sendKeysToElement(list(key = "tab"))
  remDr$screenshot(display = TRUE)
  
  # Submit search and wait for author card to load
  webElem <- findElementCustom(using = "xpath", value = "/html/body/div/div/div/router-view/div/div[1]/div[2]/div/ma-suggestion-control/div/div[1]/div[3]")
  webElem$clickElement()
  Sys.sleep(1)
  webElem <- findElementCustom(using = "css selector", value = ".author-card")
  remDr$screenshot(display = TRUE)
  
  # Click author's name in the card and wait for profile
  webElem <- findElementCustom(using = "xpath", value = "/html/body/div/div/div/router-view/ma-serp/div/div[3]/div/compose/div/ma-card/div/compose/div/div/div[1]/div/div/a/span")
  stop <- tryCatch(
    expr = {
      webElem$clickElement()
      FALSE
    },
    error = function(e) {
      if (is_empty(webElem)) {
        
        webElem <- findElementCustom(using = "css selector", value = ".ma-paper-results .au-target:nth-child(1) .au-target .au-target .au-target .ma-author-string-collection .au-target:nth-child(1) .link")
        tryCatch(
          expr = {
            webElem$clickElement()
            FALSE
          },
          error = function(e) {
            message('No profile found; skipping...')
            TRUE
          }
        )
      }
    },
    finally = {
      Sys.sleep(1)
    }
  )
  if (stop) {
    return(NULL)
  }
  webElem <- findElementCustom(using = "css selector", value = ".author .header , .name-section", attempts = 20)
  remDr$screenshot(display = TRUE)
    
  # Find affiliated university and extract text
  webElem <- findElementCustom(using = "css selector", value = ".affiliation .au-target")
  author_info$affiliation <- getElementTextCustom(webElem) %>%
    as.character
  
  # Find publications and extract text
  webElem <- findElementCustom(using = "css selector", value = ".stats .au-target:nth-child(1) .ma-statistics-item .count")
  author_info$publications <- getElementTextCustom(webElem) %>%
    gsub(",", "", .) %>%
    as.numeric
  
  # Find citations and extract text
  webElem <- findElementCustom(using = "css selector", value = ".stats .au-target:nth-child(2) .ma-statistics-item .count")
  author_info$citations <- getElementTextCustom(webElem) %>%
    gsub(",", "", .) %>%
    as.numeric
  
  # Find year of first publication and extract text
  webElem <- findElementCustom(using = "css selector", value = "#filter-from .value")
  author_info$year_start <- getElementTextCustom(webElem) %>%
    as.numeric
  
  # Find year of last publication and extract text
  webElem <- findElementCustom(using = "css selector", value = "#filter-to .value")
  author_info$year_end <- getElementTextCustom(webElem) %>%
    as.numeric
  
  # Find top topics and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-topics-filter .caption",
                               plural = TRUE)
  author_info$top_topics <- getElementTextCustom(webElem, plural = TRUE)
  
  # Find publication types and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-publication-type-filter .caption",
                               plural = TRUE)
  author_info$publication_types <- getElementTextCustom(webElem, plural = TRUE)
  
  # Find top authors and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-author-filter .caption",
                               plural = TRUE)
  author_info$top_authors <- getElementTextCustom(webElem, plural = TRUE)
  
  # Find top journals and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-journal-filter .caption",
                               plural = TRUE)
  author_info$top_journals <- getElementTextCustom(webElem, plural = TRUE)
  
  # Find top institutions and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-institution-filter .values",
                               plural = TRUE)
  author_info$top_institutions <- getElementTextCustom(webElem, plural = TRUE)
  
  # Find top conferences and extract text
  webElem <- findElementCustom(using = "css selector",
                               value = "ma-conference-filter .caption",
                               plural = TRUE)
  author_info$top_conferences <- getElementTextCustom(webElem, plural = TRUE)
  
  # Return to homepage
  remDr$navigate("https://academic.microsoft.com/home")
  webElem <- findElementCustom(using = "css selector", value = ".top", attempts = 20)
  Sys.sleep(10)
  remDr$screenshot(display = TRUE)
  return(author_info)
}
