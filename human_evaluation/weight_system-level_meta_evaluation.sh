#!/bin/bash

weight_file="CLEME_weight/weights/optimized_weights.json"

initial_weights='{
  "R:VERB:FORM": 1.0,
  "R:VERB:TENSE": 1.0,
  "M:NOUN": 1.0,
  "U:PREP": 1.0,
  "M:VERB:TENSE": 1.0,
  "R:PRON": 1.0,
  "R:SPELL": 1.0,
  "R:ADV": 1.0,
  "U:NOUN:POSS": 1.0,
  "R:ORTH": 1.0,
  "M:DET": 1.0,
  "U:OTHER": 1.0,
  "R:NOUN": 1.0,
  "U:ADV": 1.0,
  "M:ADJ": 1.0,
  "R:PREP": 1.0,
  "R:CONJ": 1.0,
  "U:NOUN": 1.0,
  "M:VERB:FORM": 1.0,
  "R:NOUN:NUM": 1.0,
  "R:NOUN:POSS": 1.0,
  "U:VERB:FORM": 1.0,
  "R:CONTR": 1.0,
  "M:ADV": 1.0,
  "U:DET": 1.0,
  "U:PUNCT": 1.0,
  "M:PRON": 1.0,
  "U:PART": 1.0,
  "R:NOUN:INFL": 1.0,
  "M:PART": 1.0,
  "M:CONJ": 1.0,
  "R:VERB:SVA": 1.0,
  "M:PUNCT": 1.0,
  "R:PUNCT": 1.0,
  "M:NOUN:POSS": 1.0,
  "U:VERB:TENSE": 1.0,
  "U:PRON": 1.0,
  "U:CONJ": 1.0,
  "R:WO": 1.0,
  "R:VERB": 1.0,
  "R:ADJ": 1.0,
  "M:PREP": 1.0,
  "R:VERB:INFL": 1.0,
  "U:ADJ": 1.0,
  "U:VERB": 1.0,
  "M:OTHER": 1.0,
  "U:CONTR": 1.0,
  "UNK": 1.0,
  "R:OTHER": 1.0,
  "R:PART": 1.0,
  "R:MORPH": 1.0,
  "R:DET": 1.0,
  "M:VERB": 1.0,
  "R:ADJ:FORM": 1.0
}'

# Write the initial weights to a JSON file
echo "$initial_weights" > "$weight_file"

# Number of iterations for weight optimization
num_iterations=50

# Learning rate (step size for weight updates)
learning_rate=1

# Output folder for M2 files
output_folder_path="CLEME/Outputs(SEEDA)/subset_m2/"

# Reference M2 file (e.g., target file)
ref_m2_file="CLEME/extracted_target_new.m2"

# Training loop for weight optimization
for iter in $(seq 1 $num_iterations); do
    echo "Iteration $iter"
    rm "metric_score/CLEME_Dep_sys_weight_optimization/sorted_f_scores_alpha_0.0.txt"
    # Iterate over alpha values from 0 to 2 with a step size of 0.05
    alpha=0
    while (( $(echo "$alpha <= 0" | bc -l) )); do
        # Iterate through each M2 file in the subset_m2 folder
        for m2_file_path in "$output_folder_path"/*; do
            if [ -f "$m2_file_path" ]; then  # Check if it's a file
                # Print separator line
                echo "--------------------------------------------------"
                echo "Processing alpha=$alpha with weights optimization"


                # Execute the command
                python3 CLEME_weight/scripts/evaluate.py --ref "$ref_m2_file" --hyp "$m2_file_path" --alpha "$alpha" --weights "$weight_file"

                # Print comparison completion message
                echo "Comparison complete for $(basename "$m2_file_path") with alpha=$alpha"
            fi
        done

        # Increment alpha by 0.05
        alpha=$(echo "$alpha + 0.05" | bc)
    done

    # Directory containing the metric scores
    metric_score_dire="metric_score/CLEME_Dep_sys_weight_optimization"

    # Human score files
    # human_scores=("human/EW_edit.txt" "human/EW_sent.txt" "human/TS_edit.txt" "human/TS_sent.txt")
    # human_score_names=("EW_edit" "EW_sent" "TS_edit" "TS_sent")

    human_scores=("human/TS_edit.txt" "human/TS_sent.txt")
    human_score_names=("TS_edit" "TS_sent")

    # Iterate over all .txt files in the metric score directory
    for filename in "$metric_score_dire"/*.txt; do
        if [ -f "$filename" ]; then  # Only process .txt files
            # Print processing message
            echo "Processing $filename..."

            # Read content from the input file and sort by system name
            sorted_scores=$(sort -t':' -k1 "$filename" | awk -F':' '{print $2}' | sed 's/^[ \t]*//')

            # Save the sorted scores to the new output file
            echo "$sorted_scores" > "$filename"

            # Print sorted scores saved message
            echo "Sorted scores saved to $filename"

            # Now perform correlation comparison
            echo "--------------------------------------------------"
            echo "Running comparison for $filename"

            # Iterate over each human score file
            for i in "${!human_scores[@]}"; do
                human_score_file="${human_scores[$i]}"
                human_score_name="${human_score_names[$i]}"
                
                # Create subdirectory for the current human score
                result_dir="correlation_score/CLEME_Dep_sys_weight_optimization/$human_score_name"
                mkdir -p "$result_dir"

                # Prepare the result file path for correlation results
                result_file="$result_dir/$(basename "$filename")"

                # Run the comparison command and redirect the output to the result file
                python3 SEEDA/utils/corr_system.py \
                    --human_score "$human_score_file" \
                    --metric_score "$filename" \
                    --system "base" > "$result_file"

                # Print completion message
                echo "Comparison complete for $filename, results saved to $result_file"
            
            done
        fi
    done

    # Extract Pearson and Spearman correlations
    pearson_corr=$(grep "Pearson:" "correlation_score/CLEME_Dep_sys_weight_optimization/TS_edit/sorted_f_scores_alpha_0.0.txt" | awk '{print $2}')
    spearman_corr=$(grep "Spearman:" "correlation_score/CLEME_Dep_sys_weight_optimization/TS_edit/sorted_f_scores_alpha_0.0.txt" | awk '{print $2}')
    echo "Pearson correlation: $pearson_corr"
    echo "Spearman correlation: $spearman_corr"

    # Compute the loss based on both correlations
    # We want to minimize the negative correlations, so we subtract them from 1.
    # Weighted sum of losses: alpha * Pearson loss + beta * Spearman loss
    # a=0.5  # You can tune this weight
    # b=0.5   # You can tune this weight

    # loss_pearson=$(echo "scale=6; 1 - $pearson_corr" | bc)
    # loss_spearman=$(echo "scale=6; 1 - $spearman_corr" | bc)

    # combined_loss=$(echo "scale=6; $a * $loss_pearson + $b * $loss_spearman" | bc)

    # python3 update_weights.py --weights "$weight_file" --pearson "$pearson_corr" --spearman "$spearman_corr" --lr 1 --n_particles 10
    # Inside your training loop:
    python3 update_weights.py \
        --weights "CLEME_weight/weights/optimized_weights.json" \
        --pearson "$pearson_corr" \
        --spearman "$spearman_corr" \
        --lr 0.2  # Adjust learning rate as needed

    # Update weights based on combined loss
    # updated_weights=$(python3 update_weights.py --weights "$weight_file" --loss "$combined_loss" --lr "$learning_rate")
    # echo "$updated_weights"
    # Save the updated weights to the weight file
    # echo "$updated_weights" > "$weight_file"
    
done
