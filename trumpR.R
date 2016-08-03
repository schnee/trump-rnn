library(twitteR)
library(dplyr)
library(readr)
library(stringr)

credsFile <- "creds.csv"
if(file.exists(credsFile)) {
  creds <- read_csv(credsFile)
} else {
  stop("Need credentials")
}

apiKey <- creds$apiKey
apiSecret <- creds$apiSecret
accessToken <- creds$accessToken
accessTokenSecret <- creds$accessTokenSecret

setup_twitter_oauth(apiKey, apiSecret, accessToken, accessTokenSecret)

### ^^^^ Run manually to here

allTrumpFile <- "all-trumpDF.csv"

if(!file.exists(allTrumpFile)) {
  # first time run, so just get the what we can from twitter
  trump <- userTimeline('realDonaldTrump', n=3200, includeRts = FALSE, excludeReplies = FALSE)
  trumpDF <- bind_rows(lapply(trump, as.data.frame))
  trumpDF <- trumpDF %>% select(text,created,favoriteCount,retweetCount,id)
} else {
  oldTrumpDF <- read_csv(allTrumpFile)
  lastTweet <-  head(oldTrumpDF %>% arrange(desc(created)), n = 1)$id
  trump <- userTimeline('realDonaldTrump', n=3200, 
                        includeRts = FALSE, excludeReplies = FALSE, sinceID = lastTweet)
  newTrumpDF <- bind_rows(lapply(trump, as.data.frame))
  print(paste0("Found new tweets: ", nrow(newTrumpDF)))
  newTrumpDF <- newTrumpDF %>% select(text,created,favoriteCount,retweetCount,id)
  oldTrumpDF$id <- as.character(oldTrumpDF$id)
  trumpDF <- bind_rows(oldTrumpDF, newTrumpDF)
}

#trump <- userTimeline('realDonaldTrump', n=3200, includeRts = FALSE, excludeReplies = FALSE)
#trumpDF <- bind_rows(lapply(trump, as.data.frame))

trumpDF <- trumpDF %>% arrange(desc(created))

trumpDF %>%  write_csv(path=allTrumpFile)

# filter to just the tweets post candidacy (>2015-06-14) (he announced on 2015-06-15)

trumpDF <- trumpDF %>% filter(created > "2015-06-14")

# attempt to clean up the tweets a bit
## whack the emojis
trumpDF$txtClean <- iconv(trumpDF$text, from="utf-8", to="ASCII", sub="")
## embedded quotes
trumpDF$txtClean <- str_replace_all(trumpDF$txtClean,'\"','')
## multi-line twweets tend to look bad on output
trumpDF$txtClean <- gsub('\n',' ',trumpDF$txtClean)
## HTML encodings...
trumpDF$txtClean <- gsub("&amp;", ' ', trumpDF$txtClean)
## strip URLs
trumpDF$txtClean <- str_replace_all(trumpDF$txtClean, "(http|ftp|https):/{2}[?#&=_0-9A-Za-z\\./\\-]+", " ")
## remove orphaned schemes (prob could be worked into the above regex)
trumpDF$txtClean <- str_replace_all(trumpDF$txtClean, "(http|ftp|https)[:/]{0,3}", " ")
## remove pic.twitter.coms too
trumpDF$txtClean <- str_replace_all(trumpDF$txtClean, "pic.twitter.com[0-9A-Za-z\\./]+", " ")

# now we have only the best tweets with the best characters.
write(x = trumpDF$txtClean, file="trump.txt")
