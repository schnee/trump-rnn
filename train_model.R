library(keras)
library(tidyverse)
library(tokenizers)
library(lubridate)

devtools::load_all()

max_length <- get_max_length()

trump_df <- read_csv("./data/trump_df.csv")

text <- trump_df %>% 
  filter(!is_retweet) %>% 
  arrange(created_at) %>%
  top_n(3300, created_at) %>%
  clean_and_tokenize()


print(sprintf("Corpus length: %d", length(text)))

alphabet <- text %>%
  unique() %>%
  sort()

saveRDS(alphabet, file = "alphabet.RDS")

print(sprintf("Total characters: %d", length(alphabet)))

vectors <- get_vectors(text, alphabet, max_length)

model <- create_model(alphabet, max_length)

model_history <- fit_model(model, vectors, epochs = 40, view_metrics = TRUE)

model %>% save_model_hdf5("./trumprnn.h5")

model <- load_model_hdf5("./trumprnn.h5")

generate_phrase(model, trump_df %>% 
                  top_n(n = 2, wt = created_at) %>% 
                  clean_and_tokenize(), alphabet, max_length, 230, 0.5)

plot(model_history)

saveRDS(model_history, "model_history.RDS")
