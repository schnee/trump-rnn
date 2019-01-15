library(keras)
library(tidyverse)
library(janeaustenr)
library(tokenizers)

max_length <- 40

text <- austen_books() %>%
  filter(book == "Pride & Prejudice") %>%
  pull(text) %>%
  str_c(collapse = " ") %>%
  tokenize_characters(lowercase = FALSE, strip_non_alphanum = FALSE, simplify = TRUE)


print(sprintf("Corpus length: %d", length(text)))

chars <- text %>%
  unique() %>%
  sort()

print(sprintf("Total characters: %d", length(chars)))

dataset <- map(
  seq(1, length(text) - max_length - 1, by = 3),
  ~list(sentence = text[.x:(.x + max_length - 1)],
        next_char = text[.x + max_length])
)

dataset <- transpose(dataset)

vectorize <- function(data, chars, max_length){
  x <- array(0, dim = c(length(data$sentence), max_length, length(chars)))
  y <- array(0, dim = c(length(data$sentence), length(chars)))

  for(i in 1:length(data$sentence)){
    x[i,,] <- sapply(chars, function(x){
      as.integer(x == data$sentence[[i]])
    })
    y[i,] <- as.integer(chars == data$next_char[[i]])
  }

  list(y = y,
       x = x)
}

vectors <- vectorize(dataset, chars, max_length)

create_model <- function(chars, max_length){
  keras_model_sequential() %>%
    layer_lstm(128, input_shape = c(max_length, length(chars))) %>%
    layer_dense(length(chars)) %>%
    layer_activation("softmax") %>%
    compile(
      loss = "categorical_crossentropy",
      optimizer = optimizer_rmsprop(lr = 0.01)
    )
}

fit_model <- function(model, vectors, epochs = 1){
  model %>% fit(
    vectors$x, vectors$y,
    batch_size = 128,
    epochs = epochs
  )
  NULL
}

generate_phrase <- function(model, text, chars, max_length, diversity){

  # this function chooses the next character for the phrase
  choose_next_char <- function(preds, chars, temperature){
    preds <- log(preds) / temperature
    exp_preds <- exp(preds)
    preds <- exp_preds / sum(exp(preds))

    next_index <- rmultinom(1, 1, preds) %>%
      as.integer() %>%
      which.max()
    chars[next_index]
  }

  # this function takes a sequence of characters and turns it into a numeric array for the model
  convert_sentence_to_data <- function(sentence, chars){
    x <- sapply(chars, function(x){
      as.integer(x == sentence)
    })
    array_reshape(x, c(1, dim(x)))
  }

  # the inital sentence is from the text
  start_index <- sample(1:(length(text) - max_length), size = 1)
  sentence <- text[start_index:(start_index + max_length - 1)]
  generated <- ""

  # while we still need characters for the phrase
  for(i in 1:(max_length * 20)){

    sentence_data <- convert_sentence_to_data(sentence, chars)

    # get the predictions for each next character
    preds <- predict(model, sentence_data)

    # choose the character
    next_char <- choose_next_char(preds, chars, diversity)

    # add it to the text and continue
    generated <- str_c(generated, next_char, collapse = "")
    sentence <- c(sentence[-1], next_char)
  }

  generated
}

iterate_model <- function(model, text, chars, max_length,
                          diversity, vectors, iterations){
  for(iteration in 1:iterations){

    message(sprintf("iteration: %02d ---------------\n\n", iteration))

    fit_model(model, vectors)

    for(diversity in c(0.2, 0.5, 1)){

      message(sprintf("diversity: %f ---------------\n\n", diversity))

      current_phrase <- 1:10 %>%
        map_chr(function(x) generate_phrase(model,
                                            text,
                                            chars,
                                            max_length,
                                            diversity))

      message(current_phrase, sep="\n")
      message("\n\n")

    }
  }
  NULL
}

model <- create_model(chars, max_length)

iterate_model(model, text, chars, max_length, diversity, vectors, 40)

result <- data_frame(diversity = rep(c(0.2, 0.4, 0.6), 20)) %>%
  mutate(phrase = map_chr(diversity,
                          ~ generate_phrase(model, text, chars, max_length, .x))) %>%
  arrange(diversity)

result %>%
  sample_n(10) %>%
  arrange(diversity) %>%
  kable()
