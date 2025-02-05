#!/bin/bash

# File paths
fluency_score_path="fluency_evaluation/fluency_scores.txt"
modified_f_score_file_path="metric_score/CLEME_Dep_sys_PT-weight/sorted_f_scores_alpha_0.25.txt"
final_score_directory="metric_score/CLEME_Dep_sys_PT-weight_fluency/alpha_0.25_normalization"
mkdir -p "$final_score_directory"

# Read the fluency scores and modified scores into arrays
# Read the fluency scores into an array
#fluency_scores=()
#while IFS= read -r line; do
#    fluency_scores+=("$line")
#done < "$fluency_score_path"
#
## Read the modified f scores into an array
#modified_f_scores=()
#while IFS= read -r line; do
#    modified_f_scores+=("$line")
#done < "$modified_f_score_file_path"
#
## Iterate over gamma values from 0 to 2 with a step size of 0.1
#gamma=0
#while (( $(echo "$gamma <= 1" | bc -l) )); do
#    echo "--------------------------------------------------"
#    echo "Processing gamma=$gamma"
#
#    # Compute final scores by adding modified_f_scores and (fluency_scores * gamma)
#    final_scores=()
#    for i in "${!fluency_scores[@]}"; do
#        fluency_score="${fluency_scores[$i]}"
#        modified_f_score="${modified_f_scores[$i]}"
#
#        # Compute the final score for each entry
#        final_score=$(echo "$modified_f_score * (1 - $gamma) + $fluency_score * 4 * $gamma" | bc -l)
#        final_scores+=("$final_score")
#    done
#
#    # Create the final score file for the current gamma value
#    final_score_file="$final_score_directory/gamma_${gamma}.txt"
#    printf "%s\n" "${final_scores[@]}" > "$final_score_file"
#    echo "Final score file for gamma=$gamma saved to $final_score_file"
#
#    # Increment gamma by 0.1
#    gamma=$(echo "$gamma + 0.005" | bc)
#done

# Human score files
human_scores=("human/TS_edit.txt" "human/TS_sent.txt")
human_score_names=("TS_edit_fluency" "TS_sent_fluency")

# Iterate over all final score files in the final score directory
for filename in "$final_score_directory"/*.txt; do
    if [ -f "$filename" ]; then  # Only process .txt files
        # Now perform correlation comparison
        echo "Running comparison for $filename"

        # Iterate over each human score file
        for i in "${!human_scores[@]}"; do
            human_score_file="${human_scores[$i]}"
            human_score_name="${human_score_names[$i]}"

            # Create subdirectory for the current human score
            result_dir="correlation_score/CLEME_Dep_sys_PT-weight_fluency/alpha_0.25_normalization/$human_score_name"
            mkdir -p "$result_dir"

            # Prepare the result file path for correlation results
            result_file="$result_dir/$(basename "$filename")"

            # Run the comparison command and redirect the output to the result file
            python3 SEEDA/utils/corr_system.py \
                --human_score "$human_score_file" \
                --metric_score "$filename" \
                --system "+REF-F_GPT-3.5" > "$result_file"

            # Print completion message
            echo "Comparison complete for $filename, results saved to $result_file"
        done
    fi
done
