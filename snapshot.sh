#!/bin/bash -e

source .env

TS=$(date '+%Y%m%d_%H%M%S')
TARGET="$BACKUP_DIRECTORY/$TS"

echo "creating backup in $TARGET"

# sudo systemctl stop httpd

mkdir -p $TARGET
mysqldump -u root -p"$MYSQL_PASSWORD" kor_production | gzip -c > $TARGET/dump.sql.gz
rsync -av $KOR_DIRECTORY/SHARED/ $TARGET/shared/

# sudo systemctl start httpd

echo "done"