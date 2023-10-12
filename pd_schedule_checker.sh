#!/bin/bash

# Before running this script make sure you have PD cli installed on your machine
# sh -c "$(curl -sL https://raw.githubusercontent.com/martindstone/pagerduty-cli/master/install.sh)"\n\n
# pd update
# pd login

# List of directories to check or create
directories=("primary" "secondary")

# Loop through the list of directories
for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        # If the directory doesn't exist, create it
        mkdir -p "$dir"
        echo "Directory created: $dir"
    else
        echo "Directory already exists: $dir"
    fi
done

# Dump latest schedule for primary and secondary

pd schedule show -n "0-SREP: Weekday Primary" >> ./primary/PD_primary_schedule_`date -I`
pd schedule show -n "0-SREP: Weekday Secondary" >> ./secondary/PD_secondary_schedule_`date -I`

# Function to find and delete the older file if there's no difference
delete_older_if_no_diff() {
    local dir="$1"
    local latest_files=($(ls -t "$dir" | head -2))

    # Check if there are at least two files in the directory
    if [ ${#latest_files[@]} -ge 2 ]; then
        local file1="$dir/${latest_files[0]}"
        local file2="$dir/${latest_files[1]}"

        # Use 'diff' to compare the files and store the result in a variable
        diff_output=$(diff "$file1" "$file2")

        # Check if there are no differences
        if [ -z "$diff_output" ]; then
            # Determine which file is the newest by comparing timestamps
            if [ "$file1" -ot "$file2" ]; then
                echo "Deleting the older file: $file1"
                rm "$file1"
            else
                echo "Deleting the older file: $file2"
                rm "$file2"
            fi
        else
            echo "Files in $dir are different. No deletion performed."
        fi
    else
        echo "There are not enough files in $dir to compare."
    fi
}

# Call the function for both directories
delete_older_if_no_diff "${directories[0]}"
delete_older_if_no_diff "${directories[1]}"