#!/bin/bash

# This script is used with Zabbix to gather the output of the borg repos and place them in a "status.txt" file inside the repo

RED='\033[1;31m'
NC='\033[0m' # No Color
GREEN='\033[1;32m'
BLUE='\033[1;34m'

#check for no argments
if [ $# -eq 0 ]; then
        echo ""
        echo -e "No arguments provided. ${RED}Usage: borg-check.sh <remote|local> <path-to-status.txt-file> [ssh-host-string]${NC}"
        echo ""
        echo -e "${BLUE}remote|local ${NC}- is the repo a local repo or a remote repo over ssh"
        echo -e "${BLUE}<path to status.txt file> ${NC}- path to the status file inside the repo. If it is a remote directory, use an absolute path"
        echo -e "${BLUE}ssh-host-string ${NC}- only needed for remote repos. Should be like this: user@server.domain.com"
        echo ""
        exit 1
fi

# vars
repo_dir=$(dirname $2)
ssh_string=$3

# Uncomment to enable unencrypted repos
#export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

# Comment to disable encrypted repos
export BORG_PASSPHRASE=''

if [ $1 = 'local' ]; then
        #save output in a variable to avoid overwritting the file partially
        info=$(borg info --last 1 $repo_dir)
        check=$(borg check -v $repo_dir 2>&1)

        # write to the file with all output ready.
        echo "$info" > $2
        echo "$check" >> $2

elif [ $1 = 'remote' ]; then
        #save output in a variable to avoid overwritting the file partially
        info=$(borg info --last 1 $ssh_string:$repo_dir)
        check=$(borg check -v $ssh_string:$repo_dir 2>&1)

        # write to the file with all output ready.
        echo "$info" | ssh $ssh_string 'dd of='$2
        echo "$check" | ssh $ssh_string 'dd of='$2' oflag=append conv=notrunc'

else
        echo -e "${RED}Incorrect second parameter. Use only <remote|local>${NC}"
        exit 1
fi
