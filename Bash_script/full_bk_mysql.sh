#!/bin/bash

set -eou pipefail
[[ -n ${DEBUG:-} ]] && set -x

# Create a file ~/.my.cnf
# Insert the content below to the file:
# [client]
# user=<local_username>
# password=<local_password>
# ---> Don't hardcode sensitive data in script

LOCAL_HOST="localhost"
LOCAL_PORT="3306"
LOCAL_USER="longtruong"

REMOTE_HOST="remote_host"
REMOTE_USER="remote_user"
REMOTE_PASSWD="remote_pass"
REMOTE_PORT="remote_port"

timestamp=$(date +%Y%m%d)
backup_folder="/data1/longtruong/code/bk_$timestamp"

if [[ -d $backup_folder ]]; then
    rm -rf $backup_folder
fi

mkdir -p $backup_folder

databases=$(mysql -u $LOCAL_USER -h $LOCAL_HOST -P $LOCAL_PORT \
            -e "SHOW DATABASES WHERE \`Database\` NOT IN ('mysql', 'performance_schema', 'sys', 'information_schema');" | awk 'NR > 1 {print $0}')

for db in $databases; do
    backup_file="bk_db_${db}.sql"
    # Create backup of each database in local database server
    mysqldump -u $LOCAL_USER -h $LOCAL_HOST -P $LOCAL_PORT $db > $backup_folder/$backup_file

    # Restore databases in remote database server
    #mysql -u $REMOTE_USER -p $REMOTE_PASSWD -h $REMOTE_HOST -P $REMOTE_PORT -e "CREATE DATABASES IF NOT EXIST $db;"
    #mysql -u $REMOTE_USER -p $REMOTE_PASSWD -h $REMOTE_HOST -P $REMOTE_PORT $db < $backup_folder/$backup_file
done
