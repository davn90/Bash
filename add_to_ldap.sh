#!/bin/bash

#################################
# Author: Dawid Nowicki
# Date: 27/02/2024
#
# This script will add users to ldap from file
# Version: v1.3
#################################

#################################################
#INFO
#
# Syntax for FILENAME:
#
# login, name, surname, password, role1, role2, role3
# Available roles: SUPERVISOR(SV), ADMINISTRATOR(ADM), AGENT(AG)
#
# EXAMPLE:
#
# jank, Jan, Kowalski, AbCdeFgHiJkLmNoUpRs, SV, AG
# marcinn, Marcin, Nowacki, 9abc2DEF3ghi4JKL5mno, SV
# aleksandern, Aleksander, Nowak, 123Test321test456Test, SV, AG, ADM
#
#################################################


# Define path for log
LOG_FILE="ldap_user_add.log"

# Create file to store users
touch users.ldif

# Filename parse in command line
FILENAME=$1

# Catch LDAP password as variable
read -p "LDAP Password: " -s LDAPPASS

# Define LDAP server connection parameters
HEADER="People, ACC, Altar"
BASE_DN="ou=People,o=ACC,o=Altar"
BIND_DN="cn=Manager,o=Altar"
ORGANIZATION="o=Altar"
ROLES_GROUP="ou=ivr,ou=roles,o=ACC,o=Altar"

# Check if file was given in parameter
if [ ! -f "$FILENAME" ]; then
    echo -e "\nError: User file $FILENAME not found, aborting operation"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error: User file $FILENAME not found, aborting operation" >> "$LOG_FILE"
    break
fi

#Function to create a file with group to modify
function catch_role {

        local role_name=$1
        local filename=group.ldif
        local option=$2

ldapsearch -x -LLL -w "$LDAPPASS" -D $BIND_DN -b cn=$role_name,$ROLES_GROUP > $filename

while read line; do

        if [[ $line == "dn"* ]]; then
                echo $line
                echo "changetype: modify"
                echo "$option: uniqueMember"
        fi

done < $filename

rm -f $filename

}

#Create file for adding users with admin role
catch_role "Administrator" "add" > adm_role.ldif

#Create file for adding users with supervisor role
catch_role "Supervisor" "add" > sv_role.ldif

#Create file for adding users with agent role
catch_role "Agent" "add" > ag_role.ldif

# Calculate date
CHANGE_DATE=$(echo "$(date +%s) / ( 60 * 60 * 24 )" | bc)

# Timestamp
TIMESTAMP=$(date +%Y%m%d%H%M%SZ)

# Fumction to check if user exists in LDAP
function user_in_ldap {
        local username=$1
        ldapsearch -x -LLL -w $LDAPPASS -D $BIND_DN -b $ORGANIZATION uid=$username > temp_file.ldif 2>&1

        if [ -s temp_file.ldif ]; then
        rm -f temp_file.ldif
                return 1
        else
        rm -f temp_file.ldif
                return 0
        fi

}

#Function to catch role of user
function add_role {

        local words=($1)
        local user=$2
        # Reading through each word in line to catch different roles
        for word in ${words[@]}; do

                if [[ "$word" == "SV"* ]]; then
                        echo "uniqueMember: uid=$user,$BASE_DN" >> sv_role.ldif
                        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user role Supervisor have been granted" >> "$LOG_FILE"
                elif [[ "$word" == "ADM"* ]]; then
                        echo "uniqueMember: uid=$user,$BASE_DN" >> adm_role.ldif
                        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user role Administrator have been granted" >> "$LOG_FILE"
                elif [[ "$word" == "AG"* ]]; then
                        echo "uniqueMember: uid=$user,$BASE_DN" >> ag_role.ldif
                        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user role Agent have been granted" >> "$LOG_FILE"
                fi
done

}


#Function to check length of login
function check_login_length {

    local login="$1"
    if [ ${#login} -gt 20 ]; then
        return 1
    else
        return 0
    fi

}

#Function to check length of name plus surname
function check_name_surname_length {

    local name="$1"
    local surname="$2"
    local result="$name $surname"
    if [ ${#result} -gt 30 ]; then
        return 1
    else
        return 0
    fi

}


# Adding user to LDAP
while read line; do
# Reading each line
user=$(echo ${line} | awk '{print $1}' | tr -d ',')
name=$(echo ${line} | awk '{print $2}' | tr -d ',')
surname=$(echo ${line} | awk '{print $3}' | tr -d ',')
password=$(echo ${line} | awk '{print $4}' | tr -d ',')

# If login is greater than 20 charactercs do not add user and continue
check_login_length "$user"
if [ $? -eq 1 ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user skipped. Username exceeds 20 characters." >> "$LOG_FILE"
        continue
fi
# If name and username is greater than 30 charactercs do not add user and continue
check_name_surname_length "$name" "$surname"
if [ $? -eq 1 ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user skipped. $name and $surname exceeds 30 characters." >> "$LOG_FILE"
        continue
fi

# Check if user already exists
user_in_ldap "$user"
if [ $? -eq 1 ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user already exists in LDAP, skipping" >> "$LOG_FILE"
        continue
fi

# Prepare file to add users
echo -e "# $user, $HEADER
dn: uid=$user,$BASE_DN
uid: $user
objectClass: account
objectClass: shadowAccount
objectClass: plcomaltarAccount
plcomaltarActivationTimestamp: $TIMESTAMP
userPassword: $(slappasswd -s $password)
shadowLastChange: $CHANGE_DATE
plcomaltarPasswordHistory:
description: $name $surname
shadowInactive: -1\n" >> users.ldif

# Log outpu to file
echo "$(date +"%Y-%m-%d %H:%M:%S") - User $user add to LDAP" >> "$LOG_FILE"

# Add roles to user
add_role "$line" "$user"

done < $FILENAME

#################
#MAIN
#################

ldapadd -x -c -w "$LDAPPASS" -D $BIND_DN -f users.ldif > /dev/null 2>&1

ldapmodify -xc -w "$LDAPPASS" -D $BIND_DN -f adm_role.ldif > /dev/null 2>&1
ldapmodify -xc -w "$LDAPPASS" -D $BIND_DN -f sv_role.ldif > /dev/null 2>&1
ldapmodify -xc -w "$LDAPPASS" -D $BIND_DN -f ag_role.ldif > /dev/null 2>&1

rm -f users.ldif && rm -f *_role.ldif

echo -e "\nUser addition process completed. Log saved to $LOG_FILE"
