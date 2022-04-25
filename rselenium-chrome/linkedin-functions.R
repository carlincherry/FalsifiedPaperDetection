# linkedin-functions.R ----------------------------------------------------
# Part of our web crawler. Adds functions to the environment for scraping 
# LinkedIn.
# 
# Needs Docker Desktop installed and a keyring named “usc” configured with a 
# username/password set up for a LinkedIn account. For more details on 
# configuring a keyring, see the tutorial script 
# “rselenium-chrome/keyring/r-keyring-tutorial.R”
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
suppressPackageStartupMessages(library("keyring"))

linkedinLogin <- function(email) {
  
  if (!("usc" %in% keyring_list()$keyring)) {
    stop('No keyring "usc" detected; please configure according to instructions in []')
  }
  
  if (nrow(key_list(service = "linkedin", keyring = "usc")) == 0) {
    stop('No key "linkedin" (case sensitive) detected; please configure according to instructions in []')
  }
  
  remDr$navigate("https://www.linkedin.com/login")
  
  webElem <- findElementCustom(using = "css selector", value = "#username")
  webElem$clearElement()
  webElem$sendKeysToElement(list(email))
  Sys.sleep(1)
  
  webElem <- findElementCustom(using = "css selector", value = "#password")
  webElem$clearElement()
  webElem$sendKeysToElement(list(key_get(service = "linkedin", 
                                         username = key_list(service = "linkedin", keyring = "usc")$username, 
                                         keyring = "usc")))
  Sys.sleep(1)
  
  webElem <- findElementCustom(using = "css selector", value = ".from__button--floating")
  webElem$clickElement()
  Sys.sleep(5)
  
  if (grepl("add-phone", remDr$getCurrentUrl())) {
    webElem <- findElementCustom(using = "css selector", value = ".secondary-action")
    webElem$clickElement()
    Sys.sleep(5)
  }
  #remDr$screenshot(display = TRUE)
}

linkedinGetProfileLinks <- function(query) {
  webElem <- findElementCustom(using = "css selector", value = ".always-show-placeholder")
  webElem$clearElement()
  webElem$clickElement()
  webElem$sendKeysToElement(list(query))
  webElem$sendKeysToElement(list(key = "enter"))
  Sys.sleep(5)
  remDr$screenshot(display = TRUE)
  
  webElem <- findElementCustom(using = "xpath", value = "//a[@href]", plural = TRUE)
  
  all_links <- sapply(
    webElem,
    function(x) {
      unlist(x$getElementAttribute("href"))
    }
  )
  
  profile_links <- unique(all_links[which(grepl("/in/", all_links))])
}

linkedinGetProfileData <- function(profile_url) {
  remDr$navigate(profile_url)
  Sys.sleep(5)
  remDr$screenshot(display = TRUE)
  
  webElem <- findElementCustom(using = "id", value = "education-section")
  text <- getElementTextCustom(webElem)
  
  if (is.na(text)) {
    highest_degree <- ""
    degree_area <- ""
  } else {
    highest_degree <- str_extract(text, "(?<=Degree Name\\n).+?(?=(\\n)|.$)")
    degree_area <- str_extract(text, "(?<=Field Of Study\\n).+?(?=(\\n)|.$)")
    if (is.na(highest_degree) & is.na(degree_area)) {
      highest_degree <- ""
      degree_area <- ""
    }
  }
  
  profile_info <- data.frame(
    url = profile_url,
    highest_degree = highest_degree,
    degree_area = degree_area,
    stringsAsFactors = FALSE
  )
}
