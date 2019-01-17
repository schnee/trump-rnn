library(rtweet)
library(readr)
library(dplyr)

initialize_twitter <- function() {
  credsFile <- "creds.csv"
  if (file.exists(credsFile)) {
    creds <- read_csv(credsFile)
  } else {
    stop("Need credentials")
  }
  
  token <- create_token(
    app = "magadlibs",
    consumer_key = creds$consumer_key,
    consumer_secret = creds$consumer_secret,
    access_token = creds$access_token,
    access_secret = creds$access_secret
  )
  token
}