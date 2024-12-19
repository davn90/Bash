#!/bin/bash

# Define variables
SOURCE_FILE="mzInterfaces.jar"
DESTINATION_DIR="/usr2/www/tomcat/APP_DATA/ACCutil/mi/mi.interfaces"
DESTINATION_FILE="$DESTINATION_DIR/mzInterfaces.jar"

# Check if the source file exists
if [ -f "$SOURCE_FILE" ]; then
    echo "Source file found."

    # Check if the destination file already exists
    if [ -f "$DESTINATION_FILE" ]; then
        echo "File $DESTINATION_FILE already exists. Renaming..."

        # Rename the existing file with a timestamp
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        mv "$DESTINATION_FILE" "$DESTINATION_FILE.$TIMESTAMP"

        if [ $? -eq 0 ]; then
            echo "Existing file renamed to $DESTINATION_FILE.$TIMESTAMP"
        else
            echo "Error: Failed to rename the existing file."
            exit 1
        fi
    fi

    # Copy the source file to the destination
    echo "Copying $SOURCE_FILE to $DESTINATION_DIR..."
    cp "$SOURCE_FILE" "$DESTINATION_DIR"

    if [ $? -eq 0 ]; then
        echo "File copied successfully."

        # Check ownership of the copied file
        FILE_OWNER=$(stat -c '%U' "$DESTINATION_FILE")
        FILE_GROUP=$(stat -c '%G' "$DESTINATION_FILE")

        if [ "$FILE_OWNER" != "root" ] || [ "$FILE_GROUP" != "root" ]; then
            echo "File ownership is not root:root. Changing ownership..."
            chown root:root "$DESTINATION_FILE"

            if [ $? -eq 0 ]; then
                echo "Ownership changed to root:root."
            else
                echo "Error: Failed to change ownership to root:root."
                exit 1
            fi
        else
            echo "File ownership is already root:root."
        fi
    else
        echo "Error: Failed to copy the file."
        exit 1
    fi
else
    echo "Error: Source file $SOURCE_FILE does not exist."
    exit 1
fi
