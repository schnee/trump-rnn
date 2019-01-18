library(keras)
library(tidyverse)
library(tokenizers)
library(lubridate)

get_max_length <- function() {
  max_length <- 40
}

#' clean_and_tokenize
#'
#' @param df 
#'
#' @return
#' @export
#'
#' @examples
clean_and_tokenize <- function(df) {
  df %>%
    mutate(text = iconv(text, from="utf-8", to="ASCII", sub="")) %>%
    ## embedded quotes
    mutate(text = str_replace_all(text,'\"','')) %>%
    mutate(text = str_replace_all(text, "(http|ftp|https):/{2}[%+!:?#&=_0-9A-Za-z\\./\\-]+", " ")) %>%
    mutate(text = str_replace_all(text, "&amp;", ' ')) %>%
    pull(text) %>%
    str_c(collapse = " ") %>%
    tokenize_characters(lowercase = FALSE, strip_non_alphanum = FALSE, simplify = TRUE)
}

#' get_vectors
#'
#' @param text 
#' @param alphabet 
#' @param max_length 
#'
#' @return
#' @export
#'
#' @examples
get_vectors <- function(text, alphabet, max_length) {
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
  
  vectors <- vectorize(dataset, alphabet, max_length)
  vectors
}

#' create_model
#'
#' @param chars 
#' @param max_length 
#'
#' @return
#' @export
#'
#' @examples
create_model <- function(chars, max_length){
  keras_model_sequential() %>%
    bidirectional(layer_cudnn_lstm(units=256, input_shape = c(max_length, length(chars)))) %>%
    layer_dropout(rate = 0.5) %>%
    layer_dense(length(chars)) %>%
    layer_activation("softmax") %>%
    compile(
      loss = "categorical_crossentropy",
      optimizer = optimizer_adam(lr = 0.001)
    )
}

#' fit_model
#'
#' @param model 
#' @param vectors 
#' @param epochs 
#'
#' @return
#' @export
#'
#' @examples
fit_model <- function(model, vectors, epochs = 1, view_metrics = FALSE){
  model %>% fit(
    vectors$x, vectors$y,
    batch_size = 32,
    epochs = epochs,
    validation_split= 0.1,
    view_metrics = view_metrics
  )
}

#' generate_phrase
#'
#' @param model 
#' @param seedtext 
#' @param chars 
#' @param max_length 
#' @param output_size 
#' @param diversity 
#'
#' @return
#' @export
#'
#' @examples
generate_phrase <- function(model, seedtext, chars, max_length, output_size = 200, diversity){
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

  convert_sentence_to_data <- function(sentence, chars){
    x <- sapply(chars, function(x){
      as.integer(x == sentence)
    })
    array_reshape(x, c(1, dim(x)))
  }
  
  # the inital sentence is from the text
  start_index <- sample(1:(length(seedtext) - max_length), size = 1)
  sentence <- seedtext[start_index:(start_index + max_length - 1)]
  generated <- ""
  
  # while we still need characters for the phrase
  for(i in 1:(output_size)){
    
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