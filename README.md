# trump-rnn - Make Neural Nets Great Again!
---


> #TrumpPence16  
> #Jebly #PresidentTrump #ImWithYou #VoteDo President  
> @piersmissen: So far the truth get @realDonaldTrump like your teams

*seeded with "#TrumpPence16", 5 layer, 512 node neural net*

Inspired by [the Obama speech generator](https://medium.com/@samim/obama-rnn-machine-generated-political-speeches-c8abd18a2ea0#.3and4fbdf), I decided to try to generate political tweets. And since, really, only one candidate has the best tweets, I trained the neural net on [realDonaldTrump](https://twitter.com/realDonaldTrump)'s tweets. Someday, you may see these via [TrumpRnn](https://twitter.com/TrumpRnn).

h/t to https://github.com/samim23/obama-rnn/, https://github.com/jcjohnson/torch-rnn, https://github.com/crisbal/docker-torch-rnn, and https://github.com/sashaperigo/Trump-Tweets. 

---
# Setup

Get R set up so that you can leverage the TwitteR, dplyr, readr, and stringr libraries.

Fork/clone this repo.

Set up a Twitter App so that the TwitteR can extract new tweets. See section 3 of the Twitter client for R PDF file (which you will get when you setup R). We're using a headless environmentment here, so you'll need four bits of authentication material.
... You'll need to create a file called creds.csv, with these columns: "id, apiKey,apiSecret,accessToken,accessTokenSecret". ID is your twitter user id.

Open trumpR.R and manually execute each line (this is to get Twitter authenticated, which could be refactored out).
... After this step, the "all-trumpDF.csv" file will be updated with whatever new tweets were found and a file called "trump.txt" will have been generated. The txt file contains the neural net training corpus

Now use torch-rnn to train the neural net. I used a [docker image](https://github.com/crisbal/docker-torch-rnn) to do all of this; your mileage may vary.

Preprocess the trump.txt file using something that looks like this:

```bash
python scripts/preprocess.py \
  --input_txt /bschneeman/projects/github.com/trump-rnn/trump.txt \
  --output_h5 /bschneeman/projects/github.com/trump-rnn/trump.h5 \  
  --output_json /bschneeman/projects/github.com/trump-rnn/trump.json
```

Train the model using something like this:

```bash
th train.lua -gpu -1 -input_h5 /bschneeman/projects/github.com/trump-rnn/trump.h5 \
  -input_json /bschneeman/projects/github.com/trump-rnn/trump.json \
  -checkpoint_name /bschneeman/projects/github.com/trump-rnn/cv/checkpoint \
  -num_layers 3 \
  -rnn_size 256
```
If you can do this with a GPU array, that would be best.

Generate tweets with something like this:

```bash
th sample.lua -length 140 -gpu -1  -verbose 1 \ 
  -checkpoint /bschneeman/projects/github.com/trump-rnn/cv/checkpoint_1000.t7 \
  -start_text "#IHaveTheBestNeurons" 
```

If you want, this repo has "trump-20160802.t7" in it. So you can generate tweets by referencing that checkpoint file in the command above.