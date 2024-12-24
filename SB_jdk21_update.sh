#!/bin/bash

# Define variables
springboot_dir="/usr2/www/tomcat/springboot"  # Path to Spring Boot directory
search_string="has been compiled by a more recent version of the Java Runtime (class file version 61.0)"  # String to search for in logs
config_file="conf/env.cfg"  # Path to the configuration file
logs_file="logs"  # Pattern to match log files in the 'logs' directory

# Function to add or update JDK21 settings in the config file
add_or_update_jdk_settings() {
    local config_path="$1"

    if [ -f "$config_path" ]; then
        # Check if both JAVA_VERSION=21 and JAVA_VENDOR=openjdk exist
        if grep -q "JAVA_VERSION=21" "$config_path" && grep -q "JAVA_VENDOR=openjdk" "$config_path"; then
            echo "Config file $config_path already contains JAVA_VERSION=21 and JAVA_VENDOR=openjdk. No changes made."
        else
            # Check if JAVA_VERSION exists with a different value
            if grep -q "JAVA_VERSION=" "$config_path"; then
                echo "Updating JAVA_VERSION to 21 in $config_path..."
                sed -i 's/JAVA_VERSION=.*/JAVA_VERSION=21/' "$config_path"
            else
                echo "Adding JAVA_VERSION=21 to $config_path..."
                sed -i '/# Java Memory/i\
JAVA_VERSION=21' "$config_path"
            fi

            # Check if JAVA_VENDOR=openjdk exists; if not, add it
            if ! grep -q "JAVA_VENDOR=openjdk" "$config_path"; then
                echo "Adding JAVA_VENDOR=openjdk to $config_path..."
                sed -i '/# Java Memory/i\
JAVA_VENDOR=openjdk' "$config_path"
            fi

            echo "JDK21 update completed for $config_path."
        fi
    else
        echo "Config file $config_path does not exist."
    fi
}

# Loop through the subdirectories in the Spring Boot directory
for app_dir in "$springboot_dir"/*; do
    if [ -d "$app_dir" ]; then
        app_name_only=$(basename "$app_dir")
        
        # Search for the string in the logs
        if grep -qrl "$search_string" "$app_dir/$logs_file"; then
            read -p "Add JDK21 update to env.cfg for: $app_name_only (y/n/abort all): " user_input
            case "$user_input" in
                y)
                    config_file_path="$app_dir/$config_file"
                    add_or_update_jdk_settings "$config_file_path"
                    ;;
                n)
                    echo "No changes made to the config file for: $app_name_only."
                    ;;
                "abort all")
                    echo "Aborting all updates. Exiting the script."
                    exit 0
                    ;;
                *)
                    echo "Invalid input. Skipping changes for this application."
                    ;;
            esac
        else
            echo "No match found for the string in logs for application: $app_name_only."
        fi
    fi
done
