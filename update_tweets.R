library(rtweet)
library(readr)
library(dplyr)

handle <- "realDonaldTrump"

devtools::load_all("./packages/tweetlstm/")

credsFile <- "creds.csv"
if (file.exists(credsFile)) {
  creds <- read_csv(credsFile)
} else {
  stop("Need credentials")
}

token <- initialize_twitter(creds)

trump_df <- read_csv(
  "./data/trump_df.csv",
  col_types = cols(status_id = col_character(),
                   reply_to_user_id = col_character())
)

most_recent = trump_df %>% 
  arrange(as.numeric(status_id), created_at) %>% 
  pull(status_id) %>% last()

timeline <-
  get_timeline(user = handle, n = 3200, since_id = most_recent)

print(paste("New tweets:", nrow(timeline)))

if (nrow(timeline) > 0) {
  
  print(paste("New tweets:", nrow(timeline)))
  
  
  trump_df <- trump_df %>%
    bind_rows(timeline %>% select(colnames(trump_df))) %>%
    distinct(status_id, .keep_all = TRUE) %>%
    arrange(as.numeric(status_id), created_at)
  
  write_csv(trump_df, "./data/trump_df.csv")
  
}


