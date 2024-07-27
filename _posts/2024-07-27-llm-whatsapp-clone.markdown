---
layout: post
title:  "Finetune an LLM from whatsapp chat"
date:   2024-07-27 03:52:25
categories: llm chat clone
image: 
---
I have been very interested into LLMs as of late and I feel the best thing to learn something is to get your hands dirty with it. So that is what I did. I tried to finetune <span style="color:#CCCCCC">LLama 2</span> on my whatsapp chat history to see if I can mimic myself via the LLM. In this blog I will talk about how I did that.

I learnt how to do this from [here](https://duarteocarmo.com/blog/fine-tune-llama-2-telegram) and [here](https://www.superteams.ai/blog/a-definitive-guide-to-fine-tuning-llms-using-axolotl-and-llama-factory).

<h1>Getting the data</h1>
Whatsapp gives you an option to export your chat with a specific person as a zip file. I did that and then wrote a simple python script to clean and prepare the data for training.
```
import json
file_input_name = "_chat.txt" # from whatsapp
file_output_name = "data.jsonl"

friend_1 = "name of friend 1"
friend_2 = "name of friend 2"

friend_separator = "#######"

lines = open(file_input_name,"r").readlines()
messages = []
message = ""
reading_fren_1 = True

for line in lines:
    line = line.strip()
    clean_line = ""
    if ": " in line:
        clean_line = line[line.index(": ")+2:]
    else:
        clean_line += line
    if line.startswith("["):
        if f"] {friend_1}:" in line:
            if message == "":
                reading_fren_1 = True
                message += f"{friend_separator}{friend_1}: {clean_line} "
            else:
                if reading_fren_1:
                    message += f"{clean_line} "
                else:
                    messages.append(message)
                    message = ""
                    reading_fren_1 = True
                    message += f"{friend_separator}{friend_1}: {clean_line} "
        elif f"] {friend_2}:" in line:
            if reading_fren_1:
                reading_fren_1 = False
                message += f"{friend_separator}{friend_2}: {clean_line} "
            else:
                message += f"{clean_line} "
    else:
        message += clean_line + " "

f = open(file_output_name, "w")
print(len(messages))
for message in messages:
    data_dict = {}
    data_dict["text"] = message
    json_string = json.dumps(data_dict, separators=(',', ':'), ensure_ascii=False)
    f.write(json_string + "\n")
```
During cleaning, I removed any unhelpful media and messages from the whatsapp system itself. Finally my data looked something like:
```
{"text":"#######Mayank: ohh makes sense my skin is very sensitive. #######Friend1: Not really. We got hard water filters in our shower and softeners too, and unless the softener is in your tanker, the impact is not as great "}
{"text":"#######Mayank: acha #######Friend1: Eeeesh. Be extra careful then  Good you use moisturizer now. Idk how you went without it. Some dudes are so lucky using 3 in 1 products  I don't wash my face after one night out and wake up with 4 new zits "}
{"text":"#######Mayank: hahaha all the best good night! #######Friend2: Night 🌸 I'm running out of flower emojis now "}
```
You can see that I used ###### to tell the model this is a speaker. I had around 2.5k of these datapoints.

Next I pushed this to the hugging face hub using this script:
```
from huggingface_hub import *
import pandas as pd
from sklearn.model_selection import train_test_split
from datasets import Dataset, DatasetDict
from huggingface_hub import login

# Log into Hugging Face
login(token="xxxxx")

# Read and split the dataset
llama = pd.read_json('data.jsonl', lines=True)
train_data, test_data = train_test_split(
    llama, test_size=0.10, random_state=42, shuffle=True
)

# Convert to Hugging Face Datasets
train_data = Dataset.from_pandas(train_data)
test_data = Dataset.from_pandas(test_data)

# Create a DatasetDict
ds = DatasetDict()
ds["train"] = train_data
ds["test"] = test_data

# Push to Hugging Face Hub
dataset_name = "mayanksingh2298/whatsapp-chat-clone"
ds.push_to_hub(dataset_name, branch="main", private=True)
```
Now, let's talk about how will we go about training an LLM on this data.

<h1>Infrastructure to train an LLM</h1>
I got an A100 GPU from Google Cloud, which comes with around ~40GB of GPU RAM. I trained on Llama-13b for 15 epochs in around 30 minutes. I used <span style="color:#CCCCCC">axolotl</span> framework to handle all the training and inference. As you'll see below it makes it very easy to train an LLM.

I ran into one issue using this library. My A100 GPU machine came with <span style="color:#CCCCCC">torch 2.4</span> but I learnt in [this blog](https://www.superteams.ai/blog/a-definitive-guide-to-fine-tuning-llms-using-axolotl-and-llama-factory), this framework is compatible with torch 2.1. As I followed these instructions, my train command didn't run because it couldn't figure out where cuda .so files were until I ran this command:
```
export LD_LIBRARY_PATH=/opt/conda/lib:$LD_LIBRARY_PATH
```

Some other useful debugging commands are:
```
python
import torch
torch.__version__
torch.is_cuda_available()

nvidia-smi

nvcc --version
```

<h1>Training</h1>
Axolotl is designed to "streamline the fine-tuning of LLMs". It supports a bunch of different models and training configurations. The best part? To fine-tune a model, all you is pretty much a config file. Yes, you heard that right - just a yaml file. 
Here's what my config file looked like
```
# Image: winglian/axolotl:main-py3.10-cu118-2.0.1 

base_model: meta-llama/Llama-2-13b-chat-hf
base_model_config: meta-llama/Llama-2-13b-chat-hf
model_type: LlamaForCausalLM
tokenizer_type: LlamaTokenizer

is_llama_derived_model: true

load_in_8bit: false
load_in_4bit: true
strict: false

datasets:
  - path: mayanksingh2298/whatsapp-chat-clone
    type: completion
    field: text
dataset_prepared_path: last_run_prepared
hub_model_id: mayanksingh2298/whatsapp-chat-clone
val_set_size: 0.01
output_dir: ./qlora-out

adapter: qlora
lora_model_dir:

sequence_len: 4096
eval_sample_packing: false
sample_packing: true
pad_to_sequence_len: true

lora_r: 32
lora_alpha: 16
lora_dropout: 0.05
lora_target_modules:
lora_target_linear: true
lora_fan_in_fan_out:

wandb_project: "whatsapp-chat-clone"
wandb_entity:
wandb_watch:
wandb_run_id:
wandb_log_model: "checkpoint"

gradient_accumulation_steps: 4
micro_batch_size: 2
num_epochs: 10
optimizer: paged_adamw_32bit
lr_scheduler: cosine
learning_rate: 0.0002

train_on_inputs: false
group_by_length: false
bf16: true
fp16: false
tf32: false

gradient_checkpointing: true
early_stopping_patience:
resume_from_checkpoint:
local_rank:
logging_steps: 1
xformers_attention:
flash_attention: true

warmup_steps: 10
eval_steps: 20
eval_table_size: 5
save_steps:
debug:
deepspeed:
weight_decay: 0.0
fsdp:
fsdp_config:
special_tokens:
  bos_token: "<s>"
  eos_token: "</s>"
  unk_token: "<unk>"
```
This is how I ran it
```
huggingface-cli login --token hf_MY_HUGGINGFACE_TOKEN_WITH_WRITE_ACCESS
wandb login MY_WANDB_API_KEY
accelerate launch -m axolotl.cli.train config.yaml
```
And we were off to the races. With a single command, I was fine-tuning Llama 2 on my custom dataset. While training, Axolotl automatically logs everything to Weights & Biases, so we can monitor how the losses are evolving. As a bonus, it also shows the model outputs so that I can follow how to model is improving its generation during training.

<h1>Inference</h1>
Using Axolotl, inference is also pretty straightforward: All I need to do is download the model, and launch the Axolotl inference command:
```
# download from fine tuned repo
git lfs install
git clone https://huggingface.co/mayanksingh2298/whatsapp-chat-clone 

# run axolotl inference
accelerate launch -m axolotl.cli.inference config.yaml --lora_model_dir="./whatsapp-chat-clone" --gradio
```
This hosts a GUI on a browser and I give it instructions like:
```
######Mayank: What is your name? ######Friend1:
```
And it would complete it.
