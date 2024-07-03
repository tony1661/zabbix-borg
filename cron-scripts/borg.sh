#!/bin/bash
# This script is used with Zabbix to gather the output of the borg repos and place them in a "status.txt" file inside the repo

# Uncomment to enable unknown unencrypted repos
#export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes

# Uncomment to enable encrypted repos and set the passphrase
#export BORG_PASSPHRASE=''


RED='\033[1;31m'
NC='\033[0m' # No Color
GREEN='\033[1;32m'
BLUE='\033[1;34m'

#check for no argments
if [ $# -eq 0 ]; then
        echo ""
        echo -e "No arguments provided. ${RED}Usage:${NC} borg.sh <info|check> <remote|local> <path-to-status.txt-file>"
        echo -e "${RED}Example:${NC} borg-check.sh info local /data/home/borg/status.txt"
        echo -e "${RED}Example:${NC} borg-check.sh check remote user@server.domain.com:/data/home/borg/status.txt"
        echo ""
	echo -e "${BLUE}info|check ${NC}- the borg task that should be run"
        echo -e "${BLUE}remote|local ${NC}- is the repo a local repo or a remote repo over ssh"
        echo -e "${BLUE}<path to status.txt file> ${NC}- path to the status file inside the repo. Use an absolute path"
        echo ""
        exit 1
fi

if [ $2 = 'local' ]; then
	status_file=$(echo "$3") # /data/home/borg/status.txt
	repo_dir=$(dirname $status_file)

	if [ $1 = 'info' ]; then
		info=$(borg info --last 1 $repo_dir)
		echo "$info" > $status_file
	elif [ $1 = 'check' ]; then
		check=$(borg check -v $repo_dir 2>&1)
		echo 'Time: '$(date +"%Y-%m-%d %H:%M:%S") > $repo_dir'/check.txt'
		echo "$check" >> $repo_dir'/check.txt'
	fi
elif [ $2 = 'remote' ]; then
	status_file=$(echo "$3" | cut -d ":" -f 2) # /data/home/borg/status.txt
	ssh_string=$(echo "$3" | cut -d ":" -f 1)  # user@server.domain.com
	repo_dir=$(dirname $status_file)

	 if [ $1 = 'info' ]; then
                info=$(borg info --last 1 $ssh_string:$repo_dir)
                echo "$info" | ssh $ssh_string 'dd of='$status_file
        elif [ $1 = 'check' ]; then
		#check=$(borg check -v $ssh_string:$repo_dir 2>&1)
		echo 'Time: '$(date +"%Y-%m-%d %H:%M:%S") | ssh $ssh_string 'dd of='$repo_dir'/check.txt conv=notrunc'
                echo "$check" | ssh $ssh_string 'dd of='$repo_dir'/check.txt oflag=append conv=notrunc'
        fi
else
        echo -e "${RED}Incorrect second parameter. Use only <remote|local>${NC}"
        exit 1
fi
