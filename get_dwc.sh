#!/bin/bash

# Ensure the script is run as the alnet user
if [ "$(whoami)" != "alnet" ]; then
    echo "Error: This script must be run as the 'alnet' user."
    exit 1
fi

# Navigate to /tmp
cd /tmp

# Create a directory named 'Dawid'
mkdir -p Dawid

# Navigate to the newly created directory
cd Dawid

# Prompt the user for variable values
read -p "Enter value for tools.v: " tools_v
read -p "Enter value for www.v: " www_v
read -p "Enter value for php.v: " php_v

# Confirm the entered values
echo "You entered the following values:"
echo "tools.v: $tools_v"
echo "www.v: $www_v"
echo "php.v: $php_v"

# Execute CVS commands with the provided values
echo "Executing CVS commands..."
cvs co -rv${tools_v} tools
cvs co -rv${www_v} WWW
cvs co -rv${php_v} PHP

echo "CVS commands executed successfully."

# Navigate back to /tmp
cd ..

# Create a tar archive and compress it
echo "Creating and compressing the archive..."
tar -cvf Dawid.tar Dawid
gzip Dawid.tar

echo "Archive Dawid.tar.gz created successfully in /tmp."
