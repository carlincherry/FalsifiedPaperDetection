# rselenium-base-functions.R ----------------------------------------------
# Part of our web crawler. Adds functions to the environment to operate the 
# crawler. Functions use the methods from the RSelenium package as building 
# blocks.
# 
# Needs Docker Desktop installed in order to run. No input files.
# 
# Outputs nothing, but the other web crawling scripts will need the functions 
# in this one.
#
# If there are questions/comments, please contact Matt (mdlee@usc.edu).
# -------------------------------------------------------------------------

# Loading required packages
suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("lubridate"))
suppressPackageStartupMessages(library("RSelenium"))
suppressPackageStartupMessages(library("getProxy"))

seleniumActive <- function() {
  # Check if Docker container "selenium" exists
  #
  # arguments:
  # - none
  !is_empty(system('docker ps --filter "name=selenium" --format "{{.RunningFor}}"', intern = TRUE))
}

ss <- function(null) {
  # Shorthand for screenshot
  #
  # arguments:
  # - null    char; no actual use, but having an argument allows for piping e.g. remDr$navigate(url) %>% ss()
  Sys.sleep(1) 
  remDr$screenshot(display = TRUE)
}

startSession <- function(browser = "chrome", proxy = FALSE) {
  # Set up session
  # - Starts Docker container "selenium"
  # - Sets up a proxy IP setting (optional)
  # - Creates remoteDriver object "remDr"
  # - Opens a window in remDr and waits
  #
  # arguments:
  # - browser    char; browser to run, currently either "chrome" or "firefox"
  # - proxy      logical; should browser run a proxy IP? (Experimental -- works
  #              on chrome, but not firefox due to difficulties with geckodriver
  #              and setting firefox profiles)
  
  # Patch to avoid warning message from using argument show.output.on.console on non-Windows machines
  if ( Sys.info()['sysname'] != "Windows") {
    old_warn <- getOption("warn")
    options(warn = -1)
  }
  if (seleniumActive()) {
    invisible(system("docker stop selenium", show.output.on.console = FALSE))
    invisible(system("docker rm selenium", show.output.on.console = FALSE))
  }
  message('Starting Docker container "selenium"')
  invisible(system(paste0("docker run --name selenium -d -p 4445:4444 selenium/standalone-",browser,":latest"), show.output.on.console = FALSE))
  if (Sys.info()['sysname'] != "Windows") {
    options(warn = old_warn)
  }
  
  extra <- list()
  if (proxy) {
    message('Setting up proxy')
    proxy <- suppressMessages(getProxy(port = "3128", country = "US", action = "get"))
    assign("proxy", proxy, envir = globalenv())
    if (browser == "chrome") {
      extra <- list(chromeOptions = list(args = list(paste0("--proxy-server=http://", proxy))))
    }
    if (browser == "firefox") {
      # Warning: still loads default profile -- needs testing
      extra <- makeFirefoxProfile(list(network.proxy.type = 1,
                                       network.proxy.http = proxy,
                                       network.proxy.http_port = 3128L))
    }
  }
  
  message('Setting up remoteDriver object "remDr"')
  message(paste0('Current browser is "', browser, '"'))
  remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4445L,
    browserName = browser,
    extraCapabilities = extra
  )
  # Warning: needs to wait for remDr to exist -- fine tune wait time as needed
  assign("remDr", remDr, envir = globalenv())
  while (!exists("remDr", envir = globalenv())) {
    Sys.sleep(1)
  }
  Sys.sleep(5)
  remDr$open(silent = TRUE)
}

endSession <- function() {
  # Tears down session
  # - Closes all windows in remDr
  # - Stops proxy
  # - Stops Docker container
  # - Miscellaneous resource cleanup
  #
  # arguments:
  # - none
  message('Closing browser windows')
  tryCatch(
    expr = {
      remDr$closeall()
    },
    error = function(e) {
      
    },
    finally = {
      if (exists("remDr")) {
        message('Removing "remDr" from Environment')
        rm("remDr", envir = globalenv())
      }
      if (exists("proxy")) {
        message('Stopping proxy')
        suppressMessages(getProxy(action = "stop"))
        rm("proxy", envir = globalenv())
      }
    }
  )
  if ( Sys.info()['sysname'] != "Windows") {
    old_warn <- getOption("warn")
    options(warn = -1)
  }
  message('Cleaning up Docker container "selenium"')
  if (seleniumActive()) {
    invisible(system("docker stop selenium", show.output.on.console = FALSE))
    invisible(system("docker rm selenium", show.output.on.console = FALSE))
  }
  if (Sys.info()['sysname'] != "Windows") {
    options(warn = old_warn)
  }
  invisible(NULL)
}

findElementCustom <- function(using = "", value = "", plural = FALSE, attempts = 3L, verbose = FALSE) {
  # Combines the functionality of methods findElement and findElements in class 
  # RSelenium::remoteDriver, and also allows for additional attempts when the 
  # browser fails to find an element (useful when waiting for an element to load)
  #
  # arguments:
  # - using    char; locator scheme to find element -- see ?remoteDriver
  # - value    char; search target -- see ?remoteDriver
  # - plural   logical; if TRUE, uses findElements, otherwise uses findElement
  # - attempts integer; total number of attempts to find an element
  # - verbose  logical; should R print messages about failed find attempts?
  
  attempts_left <- attempts
  webElement <- NULL
  if (!is.null(webElement)) {
    return(webElement)
  }
  while (attempts_left > 0 & is.null(webElement)) {
    if (plural) {
      webElement <- suppressMessages(tryCatch(
        expr = {
          remDr$findElements(using = using, value = value)
        },
        error = function(e) {
          
        }
      ))
    } else {
      webElement <- suppressMessages(tryCatch(
        expr = {
          remDr$findElement(using = using, value = value)
        },
        error = function(e) {
          
        }
      ))
    }
    attempts_left <- attempts_left - 1
    if (is.null(webElement)) {
      Sys.sleep(5)
      remDr$screenshot(display = TRUE)
      if (verbose) {
        message(paste('Could not find element. Retrying', attempts_left, 'more times'))
      }
    }
  }
  return(webElement)
}

getElementTextCustom <- function(webElement, plural = FALSE) {
  # Alters the functionality of method getElementText in class 
  # RSelenium::remoteDriver. In particular, if the input is a list of webElement 
  # objects (such as when using findElements), then this applies getElementText 
  # over them and bounds the results together as a single string. Results are
  # separated by a | symbol. If the input is a single webElement, then this is
  # equivalent to the usual getElementText.
  #
  # arguments:
  # - webElement    (class:webElement); output of methods findElement/findElements
  # - plural        logical; if TRUE, applies method getElementText over a list
  if (is.null(webElement) | is_empty(webElement)) {
    return(NA)
  }
  if (plural == TRUE) {
    output <- webElement %>%
      sapply(
        function(x) {
          unlist(x$getElementText())
        }
      ) %>%
      head(10) %>%
      paste(collapse = "|")
  } else {
    output <- unlist(webElement$getElementText())
  }
  return(output)
}

resetContainer <- function(onlyStale = FALSE) {
  # Ends the current session and starts again with the same settings. An
  # experimental feature to stabilize longer crawl jobs.
  #
  # arguments:
  # onlyStale    logical; if TRUE, R will check the time the Docker container
  #              has been up -- R will only proceed with the reset if this time
  #              is over one hour
  if (!exists("remDr", envir = globalenv())) {
    stop('No active session')
  }
  proceed <- TRUE
  if (onlyStale) {
    text <- system('docker ps --filter "name=selenium" --format "{{.RunningFor}}"', intern = TRUE)
    if (is_empty(text)) {
      proceed <- FALSE
    } else {
      proceed <- grepl("hour", text)
    }
  }
  if (proceed) {
    old_browser <- remDr$browserName
    uses_proxy <- exists("proxy", envir = globalenv())
    
    endSession()
    Sys.sleep(1)
    startSession(browser = old_browser, proxy = uses_proxy)
  }
}

switchBrowser <- function() {
  # Switches browser from chrome to firefox, and vice versa. If current browser 
  # is neither of those, R will pick randomly between the two. An experimental
  # feature to stabilize longer crawl jobs.
  #
  # arguments:
  # - none
  
  if (!exists("remDr", envir = globalenv())) {
    stop('No active session')
  }
  old_browser <- remDr$browserName
  remDr$closeall()
  endSession()
  Sys.sleep(1)
  if (old_browser == "chrome") {
    startSession(browser = "firefox")
  } else if (old_browser == "firefox") {
    startSession(browser = "chrome")
  } else {
    startSession(browser == sample(c("chrome", "firefox"), 1))
  }
}
