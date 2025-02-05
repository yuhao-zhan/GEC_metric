#!/bin/bash

# Output folder for M2 files
output_folder_path="CLEME/outputs(SEEDA)/subset_m2/"

# Reference M2 file (e.g., target file)
ref_m2_file="CLEME/extracted_target_new.m2"

# Iterate over alpha values from 0 to 2 with a step size of 0.05
alpha=0.25

while (( $(echo "$alpha <= 0.25" | bc -l) )); do
    # Iterate through each M2 file in the subset_m2 folder
    for m2_file_path in $output_folder_path/*; do
        if [ -f "$m2_file_path" ]; then  # Check if it's a file
            # Print separator line
            echo "--------------------------------------------------"
            echo "Processing alpha=$alpha"


            # Execute the command
            python3 CLEME_weight_PTScore_copy1/scripts/evaluate.py --ref "$ref_m2_file" --hyp "$m2_file_path" --alpha "$alpha"

            # Print comparison completion message
            echo "Comparison complete for $(basename "$m2_file_path") with alpha=$alpha"
        fi
    done

    # Increment alpha by 0.05
    alpha=$(echo "$alpha + 0.05" | bc)
done

# Directory containing the metric scores
metric_score_dire="metric_score/CLEME_Dep_sys_PT-weight"

# Human score files
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
            result_dir="correlation_score/CLEME_Dep_sys_PT-weight/$human_score_name"
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
