import sys
import os

from scipy.optimize import direct

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from LM_Critic.critic.perturbations import get_local_neighbors_char_level, get_local_neighbors_word_level
from LM_Critic.utils.spacy_tokenizer import spacy_tokenize_gec
import os
import numpy as np
import torch
from transformers import GPT2LMHeadModel, GPT2Tokenizer
from tqdm import tqdm

# ---------------------------
# Setup: load pretrained model and tokenizer
# ---------------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model_name = "gpt2"  # using GPT-2 as the mainstream pretrained model
model = GPT2LMHeadModel.from_pretrained(model_name)
model.to(device)
model.eval()  # set model to evaluation mode

tokenizer = GPT2Tokenizer.from_pretrained(model_name)
# GPT-2 does not have a pad_token by default; set it to the EOS token if missing.
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token

def generate_perturbations(sentence, num_perturbations=5):
    sent_toked = spacy_tokenize_gec(sentence)
    sent_perturbations_w, orig_sent = get_local_neighbors_word_level(sent_toked, max_n_samples=5, mode="refine")
    return sent_perturbations_w


def calculate_cross_entropy(sentence: str) -> float:
    """Compute cross-entropy for a sentence using GPT-2.

    Args:
        sentence (str): The input sentence.

    Returns:
        float: The average negative log likelihood (cross-entropy) per token.
    """
    # Skip empty sentences.
    if not sentence.strip():
        return None

    # Tokenize the sentence.
    inputs = tokenizer(sentence, return_tensors="pt")
    input_ids = inputs.input_ids.to(device)

    # Compute loss using the model (providing labels returns the loss).
    with torch.no_grad():
        outputs = model(input_ids, labels=input_ids)
        loss = outputs.loss  # loss is averaged over the tokens

    return loss.item()

def robustness_score(sentence, num_perturbations=5):
    original_Hx = calculate_cross_entropy(sentence)
    perturbations = generate_perturbations(sentence, num_perturbations)
    Hx_perturbed = [calculate_cross_entropy(p) for p in perturbations]
    degradation = np.mean([max(0.0, float(h - original_Hx)/original_Hx) for h in Hx_perturbed])
    return degradation

def standardized_fluency_score(sentence, ref_mean, ref_std, k=2):
    Hx = calculate_cross_entropy(sentence)
    if type(Hx) == float:
        z = (ref_mean - Hx) / ref_std  # Higher z = better fluency
    else:
        z = 0
    return 1 / (1 + np.exp(-k * z))  # Sigmoid scaling

def final_fluency(sentence, sig_score, ref_mean=4.3128, ref_std=0.7004, lambda_weight=0.7):
    robustness = robustness_score(sentence)
    # print(f"Sig_score: {sig_score}")
    # print(f"Robustness: {robustness}")
    return lambda_weight * sig_score + (1 - lambda_weight) * robustness

if __name__ == '__main__':
    system_output_dire = "Subset/subset"
    system_files = [os.path.join(system_output_dire, f) for f in os.listdir(system_output_dire) if f.endswith(".txt")]
    for files in system_files:
        with open(files, "r", encoding="utf-8") as f, open (f"Subset/standardized_fluency_scores/{os.path.basename(files)}", "r") as f_out:
            lines = f.readlines()
            num_sentences = len(lines)
            # print(f"Processing {num_sentences} sentences in {os.path.basename(files)}")
            sig_score = f_out.readlines()
            for i in tqdm(range(num_sentences)):
                # print(f" Processing sentence {i+1}: {lines[i]}, sig_score: {sig_score[i]}")
                final_fluency_score = final_fluency(lines[i], float(sig_score[i]))
                filename = os.path.join("Subset/final_fluency_scores", os.path.basename(files))
                with open(filename, "a", encoding="utf-8") as f:
                    f.write(f"{final_fluency_score}\n")