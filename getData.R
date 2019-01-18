library(jsonlite)
library(lubridate)
library(readr)
library(purrr)
library(dplyr)

urltxt <- c("https://github.com/bpb27/trump_tweet_data_archive/raw/master/condensed_2016.json.zip",
            "https://github.com/bpb27/trump_tweet_data_archive/raw/master/condensed_2017.json.zip",
            "https://github.com/bpb27/trump_tweet_data_archive/raw/master/condensed_2018.json.zip")

zipped_json_to_df <- function(url) {
  temp <- tempfile(fileext = ".zip")
  download.file(url,temp)
  data<- fromJSON(read_file(temp))
  unlink(temp)
  data
}

trump_df <- map_df(urltxt, .f=zipped_json_to_df) %>% 
  mutate(created_at = parse_date_time(created_at, orders="%a %b! %d! %H!:%M!:S! %z!* Y!"))

write_csv(trump_df, "./data/trump_df.csv")
