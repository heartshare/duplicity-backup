#!/bin/bash
# vim: ai ts=4 sts=4 et sw=4 fileencoding=utf-8
# maintainer:ukanga
MYSQL_USER=
MYSQL_PASS=
MYSQL_DB=
MYSQL_BACKUP=
MYSQL_BACKUP_SOURCE=
MYSQL_BACKUP_TARGET=

ENCRYPT_KEY=
# GNU Passphrase
PASSPHRASE=

MONGO_DUMP=
MONGO_BACKUP_TARGET=
RESTORE_MONGO_BACKUP=
RESTORE_MYSQL_BACKUP=

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

DUP_LOG=/var/log/duplicity.log

if [ -r ~/.backup_config ]; then
    source ~/.backup_config
fi

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export PASSPHRASE=$PASSPHRASE

mysql_backup()
{
    mysqldump -u $MYSQL_USER -p$MYSQL_PASS $MYSQL_DB > $MYSQL_BACKUP
}

cleanup_mysql()
{
    rm $MYSQL_BACKUP
}

mysql_duplicity_backup()
{
    duplicity --s3-use-new-style --full-if-older-than 7D --log-file $DUP_LOG --encrypt-key $ENCRYPT_KEY $MYSQL_BACKUP_SOURCE $MYSQL_BACKUP_TARGET
}

restore_mysql()
{
    duplicity restore --s3-use-new-style --hidden-encrypt-key $ENCRYPT_KEY $MYSQL_BACKUP_TARGET $RESTORE_MYSQL_BACKUP
}

mongo_backup()
{
    mongodump --out $MONGO_DUMP
}

cleanup_mongo()
{
    rm -rf $MONGO_DUMP
}

mongo_duplicity_backup()
{
    duplicity --s3-use-new-style --full-if-older-than 7D --log-file $DUP_LOG --encrypt-key $ENCRYPT_KEY $MONGO_DUMP $MONGO_BACKUP_TARGET
}

restore_mongo()
{
    duplicity restore --s3-use-new-style --hidden-encrypt-key $ENCRYPT_KEY $MONGO_BACKUP_TARGET $RESTORE_MONGO_BACKUP
}

folder_backup()
{
    duplicity --s3-use-new-style --log-file $DUP_LOG --encrypt-key $ENCRYPT_KEY $FOLDER_TO_BACKUP $FOLDER_BACKUP_TARGET
}

restore_folder()
{
    duplicity restore --s3-use-new-style --hidden-encrypt-key $ENCRYPT_KEY $FOLDER_TO_RESTORE $FOLDER_RESTORE_TARGET
}

if [ "$1" = "mysql" ]; then
    mysql_backup
    mysql_duplicity_backup
    cleanup_mysql
elif [ "$1" = "mongo" ]; then
    mongo_backup
    mongo_duplicity_backup
    cleanup_mongo
elif [ "$1" = "folder" ]; then
    if [ $# -gt 2 ]; then
        FOLDER_TO_BACKUP=$2
        FOLDER_BACKUP_TARGET=$3
        folder_backup
    else
        echo "Expecting:"
        echo "./duplicity_backup folder /path/to/backup file:///path/of/where/to/backup"
        echo "or"
        echo "./duplicity_backup folder /path/to/backup s3:///path/of/where/to/backup"
    fi
elif [[ "$1" = "restore" && "$2" = "mysql" ]]; then
    restore_mysql
elif [[ "$1" = "restore" && "$2" = "mongo" ]]; then
    restore_mongo
elif [[ "$1" = "restore" && "$2" = "folder" ]]; then
    if [ $# -gt 3 ]; then
        FOLDER_TO_RESTORE=$3
        FOLDER_RESTORE_TARGET=$4
        restore_folder
    else
        echo "./duplicity_backup restore folder file:///path/of/backup /path/of/where/to/restore"
    fi
else
    echo "duplicity_backup - Encrypted incremental backup to local or remote storage, mongo n mysql"
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset PASSPHRASE
