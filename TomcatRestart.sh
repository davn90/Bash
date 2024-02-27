#!/bin/bash


####################
# Author: Dawid
# Date: 23th-Feb-2024

# Version: v1
#
# THis script will restart tomcat.service in correct order
#####################


#set -x

# First gather all tomcat@service and put it in array
list=($(systemctl list-unit-files --type=service --state=enabled | grep tomcat | awk '{print $1}'))

# Check the status of the service and running time and errors
function check_status {
        status="$(systemctl status ${service} | grep Active | awk '{print $2}' | tr -d '()')"
        errors=($(systemctl status ${service} | grep errors | awk '{print $7, $9, $12}' | tr -d '('))

        # Maybe adding some functionality with time in future
        running="$(systemctl status ${service} | grep Active | awk '{print $9}')"
}


# Loop through list of services to retstart tomcat@main
for service in "${list[@]}"; do

# Pasring function for variables
check_status

        # If service cointain "main" restart and wait for 5 sec to ensure services are up
        if [[ "$service" == *"main"* && "$status" == "active" ]] ; then
                sudo systemctl restart $service
                sleep 5
                check_status
                echo "Service $service restarted with status $status"
                echo "${errors[0]} errors, ${errors[1]} non-critic fails, ${errors[2]} initialize errors and service is running for $running"
                break
        fi
done

# Loop through list of services to retstart tomcat@util
for service in "${list[@]}"; do

check_status

        if [[ "$service" == *"util"* && "$status" == "active" ]] ; then
                sudo systemctl restart $service
                check_status
                echo "Service $service restarted with status $status"
                echo "${errors[0]} errors, ${errors[1]} non-critic fails, ${errors[2]} initialize errors and service is running for $running"
                break
        fi
done

# Loop through list to restart rest of the services
for service in "${list[@]}"; do

check_status

        if [[ "$service" != *"main"* && "$service" != *"util"* && "$status" == "active" ]] ; then
                sudo systemctl restart $service
                check_status
                echo "Service $service restarted with status $status"
                echo "${errors[0]} errors, ${errors[0]} non-critic fails, ${errors[0]} initialize errors and service is running for $running"
        fi
done
