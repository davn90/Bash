#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Ensure required files are present in the same directory as the script
echo "Checking for required files in the script directory..."
if [ ! -f "$SCRIPT_DIR/remi-safe.repo" ]; then
    echo "Error: remi-safe.repo is not found in the script directory ($SCRIPT_DIR). Aborting script."
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/al_apache2-common-php82remi-2.4-3.altar.el8.noarch.rpm" ]; then
    echo "Error: al_apache2-common-php82remi-2.4-3.altar.el8.noarch.rpm is not found in the script directory ($SCRIPT_DIR). Aborting script."
    exit 1
fi

# Modify remi-safe.repo to disable GPG checks before moving
echo "Modifying remi-safe.repo to disable GPG checks"
sed -i 's/^gpgcheck=1/gpgcheck=0/' "$SCRIPT_DIR/remi-safe.repo"
sed -i 's/^repo_gpgcheck=1/repo_gpgcheck=0/' "$SCRIPT_DIR/remi-safe.repo"

# Move the repository file
echo "Moving remi-safe.repo to /etc/yum.repos.d/"
mv "$SCRIPT_DIR/remi-safe.repo" /etc/yum.repos.d/

# Check the status of apache.service
echo "Checking the status of apache.service"
if systemctl is-active --quiet apache.service; then
    echo "apache.service is running. Stopping it..."
    systemctl stop apache.service
else
    echo "apache.service is not running."
fi

# Remove existing PHP packages
echo "Removing PHP packages..."
if ! yum remove -y php\*; then
    echo "Failed to remove PHP packages. Aborting script."
    exit 1
fi

# Attempt to install the specified package
echo "Installing al_apache2-common-php82remi-2.4-3.altar.el8.noarch.rpm"
if ! yum --enablerepo=remi-safe install -y "$SCRIPT_DIR/al_apache2-common-php82remi-2.4-3.altar.el8.noarch.rpm"; then
    echo "Installation failed. Aborting script."
    exit 1
fi

echo "Installation successful."

# Navigate to /etc/httpd/conf.d and handle php82-php.conf
echo "Checking for php82-php.conf in /etc/httpd/conf.d"
cd /etc/httpd/conf.d || exit
if [ -f php82-php.conf ]; then
    echo "php82-php.conf exists. Creating backup and disabling it."
    cp -p php82-php.conf php82-php.conf.R
    echo "# disable" > php82-php.conf
else
    echo "php82-php.conf does not exist."
fi

# Navigate to /etc/httpd/conf.modules.d and handle 20-php82-php.conf
echo "Checking for 20-php82-php.conf in /etc/httpd/conf.modules.d"
cd /etc/httpd/conf.modules.d || exit
if [ -f 20-php82-php.conf ]; then
    echo "20-php82-php.conf exists. Creating backup and disabling it."
    cp -p 20-php82-php.conf 20-php82-php.conf.R
    echo "# disable" > 20-php82-php.conf
else
    echo "20-php82-php.conf does not exist."
fi

# Update /usr2/www/apache/conf/httpd-altar.conf
echo "Updating /usr2/www/apache/conf/httpd-altar.conf"
if [ -f /usr2/www/apache/conf/httpd-altar.conf ]; then
    sed -i 's/mod_php[57]\.c/php_module/g' /usr2/www/apache/conf/httpd-altar.conf
else
    echo "/usr2/www/apache/conf/httpd-altar.conf does not exist."
fi

# Add timezone setting to /usr2/www/html/acc/env2.php
echo "Updating /usr2/www/html/acc/env2.php"
if [ -f /usr2/www/html/acc/env2.php ]; then
    # Add lines after "// stop PHP7.x"
    awk '/\/\/ stop PHP7.x/ { print; print "// start PHP8.x"; print "define('\'DLUGI_ADRES\'', 0);"; print "date_default_timezone_set("Europe/Warsaw")"; print "// stop PHP8.x"; next }1' /usr2/www/html/acc/env2.php > /usr2/www/html/acc/env2.php.tmp
    mv /usr2/www/html/acc/env2.php.tmp /usr2/www/html/acc/env2.php
else
    echo "/usr2/www/html/acc/env2.php does not exist."
fi

# Start apache service after all steps are done
echo "Starting apache.service..."
systemctl start apache.service

# Check if apache service started successfully
if systemctl is-active --quiet apache.service; then
    echo "apache.service started successfully."
else
    echo "Failed to start apache.service."
    exit 1
fi
