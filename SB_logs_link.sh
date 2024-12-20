#!/bin/bash

# Base path
base_path="/usr2/www/tomcat/springboot/*"

# Iterate over each directory
for dir in $base_path; do
  if [ -d "$dir" ]; then
    # Extract the subfolder name from the path
    subfolder_name=$(basename "$dir")

    # Check if 'logs' is a symbolic link
    if [ -L "$dir/logs" ]; then
      echo "Symbolic link 'logs' already exists in $dir"
    elif [ -d "$dir/logs" ]; then
      # If 'logs' is a directory, remove it
      echo "Directory 'logs' exists in $dir. Removing it as 'tomcat' user."
      sudo -u tomcat rm -rf "$dir/logs"

      # Create a symbolic link to /var/log/altar/spring/<subfolder_name>
      echo "Creating symbolic link 'logs' -> /var/log/altar/spring/$subfolder_name as 'tomcat' user."
      sudo -u tomcat ln -s "/var/log/altar/spring/$subfolder_name" "$dir/logs"
    else
      # If 'logs' neither exists as a symlink nor a directory, create the symlink directly
      echo "'logs' does not exist in $dir. Creating symbolic link as 'tomcat' user."
      sudo -u tomcat ln -s "/var/log/altar/spring/$subfolder_name" "$dir/logs"
    fi
  else
    echo "Skipping $dir - not a directory"
  fi
done
