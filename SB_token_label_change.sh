#!/bin/bash

# Prompt the user to choose whether to update a label or a token
echo "Choose what you want to update:"
echo "1. Label (e.g., label: testowe-ref.vm)"
echo "2. Token (e.g., token: 842njfew84403142)"
read -p "Enter your choice (1 or 2): " CHOICE

if [[ "$CHOICE" -eq 1 ]]; then
    TYPE="label"
elif [[ "$CHOICE" -eq 2 ]]; then
    TYPE="token"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Prompt for old and new values
read -p "Enter the current $TYPE value: " OLD_VALUE
read -p "Enter the new $TYPE value: " NEW_VALUE

# Base directory where the search begins
BASE_DIR="/usr2/www/tomcat/springboot/*/conf/"

# Construct the search and replace patterns
SEARCH_PATTERN="$TYPE: $OLD_VALUE"
REPLACE_PATTERN="$TYPE: $NEW_VALUE"

# Find files with the exact match and list them
echo "Searching for files with '$SEARCH_PATTERN'..."
MATCHING_FILES=$(grep -rl "${SEARCH_PATTERN}$" $BASE_DIR/bootstrap.yml)

if [[ -n "$MATCHING_FILES" ]]; then
    echo "The following files contain '$SEARCH_PATTERN':"
    echo "$MATCHING_FILES"

    # Ask for confirmation to proceed
    read -p "Do you want to replace '$SEARCH_PATTERN' with '$REPLACE_PATTERN' in these files? (yes/no): " CONFIRM

    if [[ "$CONFIRM" == "yes" ]]; then
        # Loop through each file and perform the replacement
        for file in $MATCHING_FILES; do
            echo "Processing file: $file"
            sed -i -E "s/${SEARCH_PATTERN}$/${REPLACE_PATTERN}/g" "$file"
            if [[ $? -eq 0 ]]; then
                echo "Successfully updated: $file"
            else
                echo "Error updating: $file"
            fi
        done

        echo "All matching files have been updated."
    else
        echo "Operation canceled."
    fi
else
    echo "No files found with the exact match '$SEARCH_PATTERN'."
fi
