#!/bin/bash

#Function funShowMessage
#Usage:
# . ./script_util.sh
# ShowMessage "Show Message 1" "Show Message 2"

echo "import script_util.sh"

function ShowMessage(){
	echo "============================== "
	while [ "$1" != "" ]; do
		echo "$1";sync
		shift
	done
	echo "============================== "
	return 0
}

# Function: CountDown
# Usage:
# CountDown 10    # wait for 10 sec
# ref: http://www.unix.com/shell-programming-and-scripting/98889-display-runnning-countdown-bash-script.html
function CountDown(){
        local OLD_IFS="${IFS}"
        IFS=":"
        local SECONDS=$1
        local START=$(date +%s)
        local END=$((START + SECONDS))
        local CUR=$START

        while [[ $CUR -lt $END ]]
        do
                CUR=$(date +%s)
                LEFT=$((END-CUR))

                printf "\r%02d:%02d:%02d" \
                        $((LEFT/3600)) $(( (LEFT/60)%60)) $((LEFT%60))

                sleep 1
        done
        IFS="${OLD_IFS}"
        echo "        "
}

# -------------------------------- String Utilitly -------------------------
#Function Append
#Usage
# Append "newstring" "test.txt"
function Append(){
	local NEWSTRING=$1
	local target_file=$2
	
	echo "Append: ${NEWSTRING} -> ${target_file}"
	echo "${NEWSTRING}"| sudo tee -a "${target_file}"
}

#Function Replace
#Usage
# Replace "OLD_STRING" "NEW_STRING" "test.txt"
function Replace(){
	local PATTERN="$1"
	local NEW="$2"
	local target_file="$3"
	
	echo "sed -i s#^${PATTERN}.*#${NEW}#" ${target_file}
	sudo sed -i "s#^${PATTERN}.*#${NEW}#" ${target_file} || { echo "Replace failed" ; exit 1; }
}


#Function Add
#Description 
# Replace "OLD_STRING" to "NEW_STRING" when "OLD_STRING" exist
# Append "newstring" when "OLD_STRING" not exist
#Usage
# Add "OLD_STRING" "NEW_STRING" "test.txt"
function Add(){
        local PATTERN="$1"
        local NEW="$2"
        local target_file="$3"
        local exist_string=$(($(sudo grep -c ^${PATTERN} ${target_file})))
        
        echo "exist_string=${exist_string}"
        if [ ${exist_string} -eq 1 ]; then {
			echo "The PATTERN ${PATTERN} exist, replace it"

			Replace "$1" "$2" "$3"

        };fi

        if [ ${exist_string} -eq 0 ]; then {
			echo "The PATTERN ${PATTERN} not exist, append it"  

			Append "$2" "$3"

        };fi
}

#Function Comment a line
#Usage:
# method 1: [abc] -> #[abc]
#      CommentString "\[abc\]"    note: backslash
# method 2: abc -> #abc
# 		CommentString "abc"
function CommentString(){
	local PATTERN_LINE=$1
	local target_file=$2
	
	echo "Comment String: ${PATTERN_LINE} -> #${PATTERN_LINE}"
	Replace "${PATTERN_LINE}" "\#${PATTERN_LINE}" "${target_file}"
}


# -------------------------------- File Utilitly -------------------------
#Function BackupFile
#Backup a file with a date-time stamp
#Return: #${result}
#Usage:
# BackupFile ${target_file}
# echo ${result}
#Ref:
#http://www.commandlinefu.com/commands/view/7292/backup-a-file-with-a-date-time-stamp
function BackupFile(){
	echo "BackupFile: $1"
	
	if [ -f $1 ]; then {
		local filename=$1; 
		local filetime=$(date +%Y%m%d_%H%M%S);
		local target_file=${filename}_${filetime}
		sudo cp ${filename} ${target_file}
		result=${target_file}
	} else {
		echo "$1 does not exist, no backup operation done!"
	};fi
}


# -------------------------------- Check Utilitly -------------------------
#Function LinkTest
#Arg
#	${1}: the nic name which you want to test
#Return
# 0: the nic was linked.
# 1: the nic was no linked.
#Usage
#ex 1:
#	LinkTest eth0
#
#ex 2:
#if LinkTest eth0; then {
#	echo "return 1"
#} else {
#	echo "return others"
#};fi
#
#
#if LinkTest eth0 && LinkTest eth1; then {
#	echo "check ok: eth0 and eth1 link ok"		
#} else {
#	echo "Please check your eth0 and eth1 conection correct"
#	return 1;
#};fi
function LinkTest(){
	local nic_ready=`sudo mii-tool | grep "link ok" | grep ${1}`
	echo Test ${1} Status
	if [ -n "${nic_ready}" ]; then {
		echo "ok: ${1} linked "
		return 0;
	} else {
		echo "fail: ${1} no link"
		return 1;
	};fi
}
