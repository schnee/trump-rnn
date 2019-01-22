library(rtweet)
library(readr)
library(dplyr)

initialize_twitter <- function(creds) {
  
  token <- create_token(
    app = "magadlibs",
    consumer_key = creds$consumer_key,
    consumer_secret = creds$consumer_secret,
    access_token = creds$access_token,
    access_secret = creds$access_secret
  )
  token
}