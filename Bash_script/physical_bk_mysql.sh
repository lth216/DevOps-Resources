#!/bin/bash

set -eou pipefail
[[ -n ${DEBUG:-} ]] && set -x

SOURCE_DIR=$(cd $(dirname $0) && pwd)
CURRENT_DATE=$(date +%Y%m%d)
BACKUP_FILE_NAME="backup_mysql_$CURRENT_DATE.tar"
REMOTE_BACKUP=0

command_exist(){
   command -v "$@" > /dev/null 2>&1
}

usage(){
    cat <<-EOF
Usage:

- Backup on local machine:
    ./backup_mysql.sh --source [BACKUP_DIR] --local-dir [LOCAL_DESTINATION]

- Backup on remote machine:
    ./backup_mysql.sh --source [BACKUP_DIR] --remote-dir [REMOTE_DESTINATION]
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --source | -s)
        BACKUP_DIR=$2
        shift 2
        ;;
    --local-dir)
        LOCAL_DIR=$2
        REMOTE_BACKUP=0
        shift 2
        ;;
    --remote-dir)
        REMOTE_DIR=$2
        REMOTE_BACKUP=1
        shift 2
        ;; 
    *)
        echo "Invalid argument $1"
        exit 1
        ;;
  esac
done 
    
user=$(whoami)
bash_c="bash -c"
do_backup(){
    if [[ $user != root ]];then
        if command_exist sudo; then
            bash_c="sudo -E bash -c"
        elif command_exist su; then
            bash_c="su $user -c"
        else
            cat <<-EOF
            Error: The installation needs root privilege to perform
            No sudo or su available for the current user.
EOF
            exit 1
        fi
    fi
    
    if ! command_exist rsync; then
        $bash_c "apt-get update -qq > /dev/null 2>&1"
        $bash_c "apt-get install -y -qq rsync"
    fi
    
    # Compress necessary files into file.tar
    $bash_c "tar -cf $BACKUP_FILE_NAME $BACKUP_DIR"

    # Send file backup to destination host
    if [[ $REMOTE_BACKUP -eq 0 ]]; then
        $bash_c "rsync -a --delete $SOURCE_DIR/$BACKUP_FILE_NAME $LOCAL_DIR > /dev/null 2>&1"
    elif [[ $REMOTE_BACKUP -eq 1 ]]; then
        $bash_c "rsync -a --delete $SOURCE_DIR/$BACKUP_FILE_NAME -e ssh $REMOTE_DIR > /dev/null 2>&1"
    fi

    # Verify if the backup is successful and completed
    if [[ $? -eq 0 ]]; then
	    echo -e "\nSuccessfully backup data to 202 LAB at date: $CURRENT_DATE" >> $SOURCE_DIR/backup.log
    else
	    echo -e "\nFailed to backup data to 202 LAB at date: $CURRENT_DATE" >> $SOURCE_DIR/backup.log
    fi
}

#----MAIN
do_backup
