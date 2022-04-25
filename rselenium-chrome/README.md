# rselenium-chrome

A series of R scripts that utilize R's RSelenium package to run web scraping in a simulated Chrome browser.

## Software

`rselenium-chrome` is built in R 3.6.2 and Docker Desktop. Downloads for the essential software are below:

* [Docker Desktop](https://docs.docker.com/install/)
* [R 3.6.2](https://www.r-project.org/)
* [RStudio](https://rstudio.com/products/rstudio/download/#download)
* [Rtools 3.5.0.4](https://cran.r-project.org/bin/windows/Rtools/) (if on Windows)

## Files
This folder involves two kinds of R scripts: 1) **setup** files that load methods to run the crawler into the environment. 2) **instruction** files with the steps given to the crawler to scrape data for the Assignment. The instruction files also include tests for demonstrating the crawler with small examples.

Setup files:

* **rselenium-base-functions.R** - contains functions to start/end crawl sessions, as well as convenience functions for operating the crawler.
* **microsoft-academic-functions.R** - contains functions for interacting with Microsoft Academic, notably its author search feature.
* **linkedin-functions.R** - contains functions for interacting with LinkedIn, including finding and scraping profiles.

Instruction files:
* **crawl-bik-authors.R** - searches Microsoft Academic for authors in Bik's dataset and scrapes their profile pages.
* **crawl-linkedin.R** - searches LinkedIn for profile links on Bik's dataset, scrapes the first profile link from each search.
* **test-diagnostics.R** - runs basic crawler set up and tear down operations.
* **test-linkedin.R** - searches LinkedIn with a small example.
* **test-microsoft-academic.R** - searches Microsoft Academic with a small example.


### Setup

Configuring this project involves running all the setup files. To do that, open RStudio and change the working directory to the location of these files by running the following in the Console:

```
# Setting working directory; replace DIRECTORY to location of the specified .R files
setwd("DIRECTORY")

# Source all setup files
source("rselenium-base-functions.R")
source("microsoft-academic-functions.R")
source("linkedin-functions.R")
```

The wrapper function `startSession()` contains all setup and customizations to run the crawler for the Assignment. This function starts up a Docker container, (optionally) sets a random proxy IP, and creates a `remoteDriver()` object in R.

If Docker does not have the latest image of Chrome, then it will attempt to pull it before starting a container. This might take a while.

```
# Start up session -- takes a while if running for first time
startSession()
```
The wrapper function `endSession()` contains all cleanup for the crawler. This closes all remote windows (note: any screenshots in the Viewer are not cleared), stops the Docker container that was running Selenium, then removes it. R then deletes any proxy and `remoteDriver()` objects.

```
# Ends session
endSession()
```

## Examples

### Basic Diagnostics

Runs the crawler through a few basic set up and tear down operations.

```
# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

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
```

### Microsoft Academic

Test if Microsoft Academic is accessible by searching for an academic dear to our hearts: Chris Mattmann (along with two other computer scientists of renown)

```
# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

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
```

### LinkedIn

Tests if LinkedIn is available by searching for our professor's profile and pulling some information from it. LinkedIn is usually on top of discouraging robots, so prolonged activity may result in getting banned.

This demo relies on a LinkedIn credentials set up on a keyring named "usc"; for more information on configuring keyrings using R's `keyring` package, see the README in the main repository.

```
# Loading required packages
library("tidyverse")
library("lubridate")
library("RSelenium")
library("getProxy")
library("keyring")

tryCatch(
  expr = {
    message('Unlocking keyring named "usc"')
    keyring_unlock(keyring = "usc")
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
```
## Credits

This project is a component of Team 03's submission of *Assignment 1: Analysis of Media and Semantic Forensics in Scientific Literature* from the USC Viterbi's INF550: Data Science at Scale, Spring 2020 course.

### Authors

* **Cherry, Carlin** - *Collaborator* - ccherry@usc.edu - 8211265507
* **Lee, Matthew** - *Initial work* - mdlee@usc.edu - 4356300240
* **May, David** - *Collaborator* - davidmay@usc.edu - 5801939142
