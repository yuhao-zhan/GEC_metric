#!/bin/bash

# Output folder for M2 files
output_folder_path="CLEME/Outputs(SEEDA)/subset_m2/"

# Reference M2 file (e.g., target file)
ref_m2_file="CLEME/extracted_target_new.m2"

# Iterate over alpha values from 0 to 2 with a step size of 0.05
alpha=0.25
while (( $(echo "$alpha <= 0.25" | bc -l) )); do
    # Iterate through each M2 file in the subset_m2 folder
    for m2_file_path in "$output_folder_path"/*; do
        if [ -f "$m2_file_path" ]; then  # Check if it's a file
            # Print separator line
            echo "--------------------------------------------------"
            echo "Processing alpha=$alpha"

            # system_name=${$(basename "$m2_file_path")%.m2}.txt
            system_name=$(basename "$m2_file_path")
            system_name="${system_name%.m2}.txt"  # Remove .m2 and add .txt
            mkdir -p "metric_score/CLEME_Dep_sentence_PT-weight/alpha_$alpha"
            system_path="metric_score/CLEME_Dep_sentence_PT-weight/alpha_$alpha/$system_name"

            # Execute the command
            python3 CLEME_weight_PTScore_copy2/scripts/evaluate.py --ref "$ref_m2_file" --hyp "$m2_file_path" --alpha "$alpha" > "$system_path"

            # Print comparison completion message
            echo "Comparison complete for $(basename "$m2_file_path") with alpha=$alpha"
        fi
    done

    # Increment alpha by 0.05
    alpha=$(echo "$alpha + 0.05" | bc)
done

# Directory containing the metric scores
metric_score_dire="metric_score/CLEME_Dep_sentence_PT-weight"

# Human score files
human_judgements=("SEEDA/data/judgments_edit.xml" "SEEDA/data/judgments_sent.xml")
human_score_names=("edit" "sent")

# # Iterate over all .txt files in the metric score directory
# for filename in "$metric_score_dire"/*.txt; do
#     if [ -f "$filename" ]; then  # Only process .txt files
#         echo "Running comparison for $filename"

        # Iterate over each human score file
#for i in "${!human_judgements[@]}"; do
#    human_score_file="${human_judgements[$i]}"
#    human_score_name="${human_score_names[$i]}"
#
#    # Create subdirectory for the current human score
#    result_dir="correlation_score/CLEME_Dep_sentence_PT-weight/$human_score_name"
#    # mkdir -p "$result_dir"
#
#    alpha=0.25
#
#    while (( $(echo "$alpha <= 0.25" | bc -l) )); do
#        # Prepare the result file path for correlation results
#        result_file="$result_dir/alpha_$alpha.txt"
#
#        # Run the comparison command and redirect the output to the result file
#        python3 SEEDA/utils/corr_sentence.py \
#            --human_score "$human_score_file" \
#            --metric_score "$metric_score_dire/alpha_$alpha" \
#            --system "base" > "$result_file"
#
#        # Print completion message
#        echo "Comparison complete for $alpha, results saved to $result_file"
#        # Increment alpha by 0.05
#        alpha=$(echo "$alpha + 0.05" | bc)
#    done
#done
