#!/bin/bash

#################################
# Author: Dawid Nowicki
# Date: 27/02/2024
#
# This script will add users to ldap from file
# Version: v1
#################################

# Create file to store users
touch users.ldif

# Catch LDAP password as variable
read -p "LDAP Password: " -s LDAPPASS

#Function to create a file with group to modify
function catch_role {

ldapsearch -x -w "$LDAPPASS" -D cn=Manager,o=Altar -b cn=$1,ou=ivr,ou=roles,o=ACC,o=Altar > $1.ldif

        local filename=$1.ldif
        local role_name=$1

while read line; do

        if [[ $line == "dn"* ]]; then
                echo $line
                echo "changetype: modify"
                echo "$2: uniqueMember"
        elif [[ $line == "# $1, ivr, roles, ACC, Altar" ]]; then
                echo $line
        fi

done < $filename

rm -f $1.ldif

}

#Create file for adding users with admin role
catch_role "Administrator" "add" > adm_role.ldif

#Create file for adding users with supervisor role
catch_role "Supervisor" "add" > sv_role.ldif

#Create file for adding users with agent role
catch_role "Agent" "add" > ag_role.ldif

# Filename parse in command line
filename=$1

# Calculate date
change_date=$(echo "$(date +%s) / ( 60 * 60 * 24 )" | bc)

# Timestamp
timestamp=$(date +%Y%m%d%H%M%SZ)

#Function to catch role of user
function add_role {

        words=($1)
        for word in ${words[@]}; do

                if [[ "$word" == "SV"* ]]; then
                        echo "uniqueMember: uid=$2,ou=People,o=ACC,o=Altar" >> sv_role.ldif
                elif [[ "$word" == "ADM"* ]]; then
                        echo "uniqueMember: uid=$2,ou=People,o=ACC,o=Altar" >> adm_role.ldif
                elif [[ "$word" == "AG"* ]]; then
                        echo "uniqueMember: uid=$2,ou=People,o=ACC,o=Altar" >> ag_role.ldif
                fi
done

}


#Function to check length of login
function check_login_length {

    local login="$1"
    if [ ${#login} -gt 20 ]; then
        echo "True"
    fi

}

#Function to check length of name plus surname
function check_name_surname_length {

    local name="$1"
    local surname="$2"
    local result="$name $surname"
    if [ ${#result} -gt 30 ]; then
	    echo "True"
    fi

}



while read line; do
# reading each line
user=$(echo ${line} | awk '{print $1}' | tr -d ',')
name=$(echo ${line} | awk '{print $2}' | tr -d ',')
surname=$(echo ${line} | awk '{print $3}' | tr -d ',')

# If login is greater than 20 charactercs do not add user and continue
if [[ $(check_login_length "$user") == "True" ]]; then
        echo "Login name $user is longer than 20 characters"
        continue
# If name and username is greater than 30 charactercs do not add user and continue
elif [[ $(check_name_surname_length "$name" "$surname") == "True" ]]; then
        echo "Name plus surname of $user is longer than 30 characters"
        continue

fi

add_role "$line" "$user"

echo -e "# $user, People, ACC, Altar
dn: uid=$user,ou=People,o=ACC,o=Altar
uid: $user
objectClass: account
objectClass: shadowAccount
objectClass: plcomaltarAccount
plcomaltarActivationTimestamp: $timestamp
userPassword: e0
shadowLastChange: $change_date
plcomaltarPasswordHistory:
description: $name $surname
shadowInactive: -1\n" >> users.ldif

done < $filename

ldapadd -x -c -w "$LDAPPASS" -D cn=Manager,o=Altar -f users.ldif

ldapmodify -xc -w "$LDAPPASS" -D cn=Manager,o=Altar -f adm_role.ldif
ldapmodify -xc -w "$LDAPPASS" -D cn=Manager,o=Altar -f sv_role.ldif
ldapmodify -xc -w "$LDAPPASS" -D cn=Manager,o=Altar -f ag_role.ldif

rm -f *.ldif

