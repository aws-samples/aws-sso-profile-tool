#!/bin/bash
#
# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#
# Syntax:
#
# ssoprofiletool <region> <start_url> [<profile_file>]
#
# <region> is the region where AWS SSO is configured (e.g., us-east-1)
# <start_url> is the AWS SSO start URL
# <profile_file> is the file where the profiles will be written (default is
#    ~/.aws/config)

ACCOUNTPAGESIZE=10
ROLEPAGESIZE=10
PROFILEFILE="$HOME/.aws/config"

if [ $# -lt 2 ];
then
    echo "Syntax: $0 <region> <start_url> [<profile_file>]"
    exit 1 
fi

if [ $# -eq 3 ];
then
    profilefile=$3
else
    profilefile=$PROFILEFILE
fi

# Get secret and client ID to begin authentication session

echo
echo -n "Registering client... "

out=`aws sso-oidc register-client --client-name 'profiletool' --client-type 'public' --region $1 --output text`

if [ $? -ne 0 ];
then
    echo "Failed"
    exit 1
else
    echo "Succeeded"
fi

secret=`awk -F ' ' '{print $3}' <<< $out`
clientid=`awk -F ' ' '{print $1}' <<< $out`

# Start the authentication process

echo -n "Starting device authorization... "

out=`aws sso-oidc start-device-authorization --client-id "$clientid" --client-secret "$secret" --start-url "$2" --region $1 --output text`

if [ $? -ne 0 ];
then
    echo "Failed"
    exit 1
else
    echo "Succeeded"
fi

regurl=`awk -F ' ' '{print $6}' <<< $out`
devicecode=`awk -F ' ' '{print $1}' <<< $out`

echo
echo "Open the following URL in your browser and sign in:"
echo
echo "$regurl"
echo
echo "Press <ENTER> after you have signed into AWS CLI to continue..."

read continue

# Get the access token for use in the remaining API calls

echo -n "Getting access token... "

out=`aws sso-oidc create-token --client-id "$clientid" --client-secret "$secret" --grant-type 'urn:ietf:params:oauth:grant-type:device_code' --device-code "$devicecode" --region $1 --output text`

if [ $? -ne 0 ];
then
    echo "Failed"
    exit 1
else
    echo "Succeeded"
fi

token=`awk -F ' ' '{print $1}' <<< $out`

# Set defaults for profiles

defregion=$1
defoutput="json"

# Retrieve accounts first

echo -n "Retrieving accounts... "

acctsfile="$(mktemp ./sso.accts.XXXXXX)"

# Set up trap to clean up temp file
trap "{ rm -f $acctsfile; echo; exit 255; }" SIGINT SIGTERM
    
aws sso list-accounts --access-token "$token" --page-size $ACCOUNTPAGESIZE --region $1 --output text > $acctsfile

if [ $? -ne 0 ];
then
    echo "Failed"
    exit 1
else
    echo "Succeeded"
fi

declare -a created_profiles

# Read in accounts

while IFS=$'\t' read skip acctnum acctname acctowner;
do
    echo
    echo "Adding roles for account $acctnum ($acctname)..."
    rolesfile="$(mktemp ./sso.roles.XXXXXX)"

    # Set up trap to clean up both temp files
    trap "{ rm -f $rolesfile $acctsfile; echo; exit 255; }" SIGINT SIGTERM
    
    aws sso list-account-roles --account-id $acctnum --access-token "$token" --page-size $ROLEPAGESIZE --region $1 --output text > $rolesfile

    if [ $? -ne 0 ];
    then
	echo "Failed to retrieve roles."
	exit 1
    fi

    while IFS=$'\t' read junk junk rolename;
    do
	echo
	echo -n "Create a profile for $rolename role? (Y/n): "
	read create < /dev/tty
	if [ -z $create ];
	then
	    :
	elif [ $create == 'n' ] || [ $create == 'N' ];
	then
	    continue
	fi
	echo
	echo -n "CLI default client Region [$defregion]: "
	read awsregion < /dev/tty
	if [ -z $awsregion ]; then awsregion=$defregion ; fi
	defregion=$awsregion
	echo -n "CLI default output format [$defoutput]: "
	read output < /dev/tty
	if [ -z $output ]; then output=$defoutput ; fi
	defoutput=$output
	p="$rolename-$acctnum"
	while [ true ]; do
	    echo -n "CLI profile name [$p]: "
	    read profilename < /dev/tty
	    if [ -z $profilename ]; then profilename=$p ; fi
	    if [ -f $profilefile ];
	    then
		:
	    else
		break
	    fi
	    
	    if [ `grep -ce "^\s*\[\s*profile\s\s*$profilename\s*\]" $profilefile` -eq 0 ];
	    then
		break
	    else
		echo "Profile name already exists!"
	    fi
	done
	echo -n "Creating $profilename... "
	echo "" >> $profilefile
	echo "[profile $profilename]" >> $profilefile
	echo "sso_start_url = $2" >> $profilefile
	echo "sso_region = $1" >> $profilefile
	echo "sso_account_id = $acctnum" >> $profilefile
	echo "sso_role_name = $rolename" >> $profilefile
	echo "region = $awsregion" >> $profilefile
	echo "output = $output" >> $profilefile
	echo "Succeeded"
	created_profiles+=("$profilename")
    done < $rolesfile
    rm $rolesfile

    echo
    echo "Done adding roles for AWS account $acctnum ($acctname)"

done < $acctsfile
rm $acctsfile

echo
echo "Processing complete."
echo
echo "Added the following profiles to $profilefile:"
echo

for i in "${created_profiles[@]}"
do
    echo $i
done
echo
exit 0
