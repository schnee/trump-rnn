library(rtweet)
library(readr)
library(dplyr)

handle <- "realDonaldTrump"

devtools::load_all()

token <- initialize_twitter()

trump_df <- read_csv("./data/trump_df.csv") %>%
  mutate(status_id = as.character(status_id)) %>%
  mutate(reply_to_user_id = as.character(reply_to_user_id))

most_recent = trump_df %>% arrange(created_at) %>% pull(status_id) %>% last()

timeline <-
  get_timeline(user = handle, n = 3200, since_id = most_recent)

if (nrow(timeline) > 0) {
  trump_df <- trump_df %>%
    bind_rows(timeline %>% select(colnames(trump_df)))
}

write_csv(trump_df, "./data/trump_df.csv")
