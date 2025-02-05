#!/bin/bash

# File paths
fluency_score_directory="fluency_evaluation/sentence_fluency"
modified_f_score_directory="metric_score/CLEME_Dep_sentence_PT-weight/alpha_0.25"
final_score_directory="metric_score/CLEME_Dep_sentence_PT-weight_fluency/alpha_0.25_normalization"
mkdir -p "$final_score_directory"

# Get the list of all txt files in the fluency score directory and the modified f score directory
fluency_files=($fluency_score_directory/*.txt)
modified_f_files=($modified_f_score_directory/*.txt)

# Iterate over gamma values from 0 to 1 with a step size of 0.005 (outer loop)
gamma=0
while (( $(echo "$gamma <= 1" | bc -l) )); do
    echo "--------------------------------------------------"
    echo "Processing gamma=$gamma"

    # Create a subdirectory for the current gamma value in final_score_directory
    gamma_directory="$final_score_directory/gamma_$gamma"
    mkdir -p "$gamma_directory"

    # Iterate over each pair of files (fluency and modified_f) and process (inner loop)
    for i in "${!fluency_files[@]}"; do
        fluency_file="${fluency_files[$i]}"
        modified_f_file="${modified_f_files[$i]}"
        filename=$(basename "$fluency_file")

        # Read the fluency scores into an array (skip empty lines)
        fluency_scores=()
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines
            if [[ -n "$line" ]]; then
                fluency_scores+=("$line")
            fi
        done < "$fluency_file"

        # Read the modified f scores into an array (skip empty lines)
        modified_f_scores=()
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines
            if [[ -n "$line" ]]; then
                modified_f_scores+=("$line")
            fi
        done < "$modified_f_file"

        # Combine the fluency and modified f scores line by line
        final_scores=()
        for i in "${!fluency_scores[@]}"; do
            fluency_score="${fluency_scores[$i]}"
            modified_f_score="${modified_f_scores[$i]}"

            # Compute the final score for each entry: modified_f_score * (1 - gamma) + fluency_score * gamma
            final_score=$(echo "$modified_f_score * (1 - $gamma) + $fluency_score * 4 * $gamma" | bc -l)
            final_scores+=("$final_score")
        done

        # Save the final scores to the appropriate subdirectory for the current gamma value
        final_score_file="$gamma_directory/${filename%.txt}.txt"
        printf "%s\n" "${final_scores[@]}" > "$final_score_file"
        echo "Final score file for $filename with gamma=$gamma saved to $final_score_file"
    done

    # After generating the final score files for the current gamma, compute the correlation
    # Directory containing the metric scores
    metric_score_dir="$final_score_directory/gamma_$gamma"

    # Human score files
    human_judgements=("SEEDA/data/judgments_edit.xml" "SEEDA/data/judgments_sent.xml")
    human_score_names=("edit_fluency" "sent_fluency")

    # Iterate over each human score file for correlation
    for i in "${!human_judgements[@]}"; do
        human_score_file="${human_judgements[$i]}"
        human_score_name="${human_score_names[$i]}"

        # Create subdirectory for the current human score
        result_dir="correlation_score/CLEME_Dep_sentence_PT-weight_fluency/alpha_0.25/$human_score_name"
        mkdir -p "$result_dir"

        alpha=0.25
        while (( $(echo "$alpha <= 0.25" | bc -l) )); do
            # Prepare the result file path for correlation results
            result_file="$result_dir/gamma_${gamma}_alpha_${alpha}.txt"

            # Run the comparison command and redirect the output to the result file
            python3 SEEDA/utils/corr_sentence.py \
                --human_score "$human_score_file" \
                --metric_score "$metric_score_dir" \
                --system "+REF-F_GPT-3.5" > "$result_file"

            # Print completion message
            echo "Comparison complete for gamma=$gamma, alpha=$alpha, results saved to $result_file"

            # Increment alpha by 0.05
            alpha=$(echo "$alpha + 0.05" | bc)
        done
    done

    # Increment gamma by 0.01
    gamma=$(echo "$gamma + 0.005" | bc)
done
