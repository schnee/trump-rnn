library(rtweet)
library(readr)
library(dplyr)
library(keras)

handle <- "realDonaldTrump"

devtools::load_all()

token <- initialize_twitter()

my_replies <- get_timeline(rtweet:::home_user()) %>% 
  #filter(reply_to_screen_name == handle) %>% 
  arrange(created_at)

trump_df <- read_csv("./data/trump_df.csv") %>%
  mutate(status_id = as.character(status_id)) %>%
  mutate(reply_to_user_id = as.character(reply_to_user_id))

# if my replies are all before the last non-retweet entry from handle, then I need to
# reply. If not, then I can sleep and wait for a new tweet.
my_last_reply_timestamp <- my_replies %>% top_n(n=1, wt = created_at) %>% pull(created_at)

the_unreplied_tweets <- trump_df %>% filter(!is_retweet) %>%
  filter(created_at > my_last_reply_timestamp) %>% 
  arrange(created_at)

if(nrow(the_unreplied_tweets) > 0) {
  reply_to_status_id <- the_unreplied_tweets %>% top_n(n=1, wt = created_at) %>% pull(status_id)
  
  # TODO - ensure that the reply to text has enough characters
  
  reply_to_txt <- trump_df %>% top_n(n=5, wt = created_at)
  
  tweet_prefix <- paste0(".@",handle, ":")
  
  model <- load_model_hdf5("./trumprnn.h5")
  alphabet <- readRDS(file = "./alphabet.RDS")
  
 
  the_reply <- generate_phrase(model = model, 
                               seedtext = reply_to_txt %>% clean_and_tokenize(),
                               chars = alphabet, 
                               max_length = get_max_length(),
                               output_size = 230 - nchar(tweet_prefix),
                               diversity = 0.4
                               )
  
  the_reply <- paste(tweet_prefix, the_reply)
  
  post_tweet(status = the_reply, in_reply_to_status_id = reply_to_status_id)
  
}
