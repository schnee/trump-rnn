library(rtweet)
library(readr)
library(dplyr)
library(keras)

handle <- "realDonaldTrump"

devtools::load_all("./packages/tweetlstm/")

max_length <- get_max_length()

credsFile <- "creds.csv"
if (file.exists(credsFile)) {
  creds <- read_csv(credsFile)
} else {
  stop("Need credentials")
}

token <- initialize_twitter(creds)

my_replies <- get_timeline(rtweet:::home_user()) %>% 
  filter(reply_to_screen_name == handle) %>% 
  arrange(created_at)

trump_df <- read_csv(
  "./data/trump_df.csv",
  col_types = cols(status_id = col_character(),
                   reply_to_user_id = col_character())
)

# look at the last days worth of tweets, and remove those that I have already replied to

the_unreplied_tweets <- trump_df %>% 
  filter(!is_retweet) %>% filter(created_at > today() - days(1)) %>% 
  anti_join(my_replies, by = c("status_id" = "reply_to_status_id")) %>% 
  distinct(status_id, .keep_all=TRUE) %>%
  arrange(created_at)

if(nrow(the_unreplied_tweets) > 0) {
  
  reply_to_tweet <- the_unreplied_tweets %>% 
    sample_n(1) 
  

  n_chars_in_tweet <- reply_to_tweet %>% clean_and_tokenize() %>% length()
  n_attempts <- 0
  
  while ((n_attempts < 10) && (n_chars_in_tweet < 2)) {
    reply_to_tweet <- the_unreplied_tweets %>% 
      sample_n(1) 
    
    
    n_chars_in_tweet <- reply_to_tweet %>% clean_and_tokenize() %>% length()
    n_attempts <- n_attempts + 1
  }
  

  
  num_reply_chars <- n_chars_in_tweet

  
  reply_chars <- reply_to_tweet %>% clean_and_tokenize()
  n_tweets <- 1
  
  # generate seed chars
  while (((num_reply_chars < max_length) && n_tweets <= 10)) {
    reply_to_txt <- trump_df %>% 
      filter(!is_retweet) %>%
      top_n(n = n_tweets, wt = created_at)
    
    reply_chars <- c(reply_chars, reply_to_txt %>% clean_and_tokenize())
    
    num_reply_chars <- length(reply_chars)
    n_tweets <- n_tweets + 1
    
  }
  
  if (num_reply_chars >= max_length) {
    
    model <- load_model_hdf5("./trumprnn.h5")
    alphabet <- readRDS(file = "./alphabet.RDS")
    
    
    the_reply <- generate_phrase(
      model = model,
      seedtext = reply_chars,
      chars = alphabet,
      max_length = get_max_length(),
      output_size = 230,
      diversity = 0.4
    )
    
    # make the status appear to be part of a whole to mask the start/stop
    the_reply <- paste0("...", the_reply, "...")
    
    post_tweet(status = the_reply, 
               in_reply_to_status_id = reply_to_tweet$status_id,
               auto_populate_reply_metadata = TRUE)
    
    print(paste0("Replying to: ", reply_to_tweet$status_id, " ", reply_to_tweet$text))
    
    print(paste("Replied with:", the_reply))
  } 
  
}
