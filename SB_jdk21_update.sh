#!/bin/bash

# Define variables
springboot_dir="/usr2/www/tomcat/springboot"  # Path to Spring Boot directory
search_string="has been compiled by a more recent version of the Java Runtime (class file version 61.0)"  # String to search for in logs
config_file="conf/env.cfg"  # Path to the configuration file
logs_file="logs"  # Pattern to match log files in the 'logs' directory

# Loop through the subdirectories in the Spring Boot directory
for app_dir in "$springboot_dir"/*; do
    if [ -d "$app_dir" ]; then
        # Extract the app name (basename of the directory)
        app_name_only=$(basename "$app_dir")

        # Search for the string in the logs
        grep -rl "$search_string" "$app_dir/$logs_file" > /dev/null 2>&1

        # Check if grep found any matches
        if [ $? -eq 0 ]; then

            # Ask for user validation (y/n/abort all)
            read -p "Add JDK21 update to env.cfg for: $app_name_only (y/n/abort all): " user_input

            # If the user inputs 'y', proceed with adding the JDK21 update to the config file
            if [[ "$user_input" == "y" ]]; then
                config_file_path="$app_dir/$config_file"

                # Check if the config file exists before modifying it
                if [ -f "$config_file_path" ]; then
                    echo "Adding JDK21 update to $config_file_path..."

                    # Use sed to insert two lines above the line containing "# Java Memory"
                    sed -i '/# Java Memory/i\
JAVA_VERSION=21\nJAVA_VENDOR=openjdk' "$config_file_path"
                    
                    echo "JDK21 update added to the config file."
                else
                    echo "Config file $config_file_path does not exist."
                fi

            # If the user inputs 'n', skip and continue to the next application
            elif [[ "$user_input" == "n" ]]; then
                echo "No changes made to the config file for: $app_name_only."

            # If the user inputs 'abort all', stop the script immediately
            elif [[ "$user_input" == "abort all" ]]; then
                echo "Aborting all updates. Exiting the script."
                exit 0

            else
                echo "Invalid input. Skipping changes for this application."
            fi
        else
            echo "No match found for the string in logs for application: $app_name_only"
        fi
    fi
done
