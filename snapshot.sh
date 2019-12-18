#!/bin/bash -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $ROOT/.env

TS=$(date '+%Y%m%d_%H%M%S')
TARGET="$BACKUP_DIRECTORY/$TS"

echo "creating backup in $TARGET"

# sudo systemctl stop httpd

mkdir -p $TARGET
mysqldump -u root -p"$MYSQL_PASSWORD" kor_production | gzip -c > $TARGET/dump.sql.gz
rsync -a $KOR_ROOT/SHARED/ $TARGET/shared/

# sudo systemctl start httpd

echo "done"