#!/bin/bash -e

CMD=${1:-manual}

# ensure db dump is up to date
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $ROOT/.env
REPO="$BACKUP_DIRECTORY/borg"

# sudo systemctl stop httpd

mysqldump -u root -p"$MYSQL_PASSWORD" kor_production | gzip -c > $KOR_SHARED/dump.sql.gz

# sudo systemctl start httpd

NAME="kor"
BIN="/usr/bin/borg"
OPTS="--compression none -v --show-rc --progress --info"
OPTS="$OPTS --stats --patterns-from $ROOT/snapshot.patterns"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

function init {
  $BIN init --encryption=repokey $REPO
}

function list {
  $BIN list -v $REPO
}

function nightly {
  # do the backup and clean up
  $BIN create $OPTS $REPO::$NAME-{now:%Y-%m-%d-%H-%M-%S}
  $BIN prune -v --list --keep-daily=30 --keep-weekly=8 --keep-monthly=24 --prefix=$NAME $REPO
}

function manual {
  $BIN delete $REPO::$NAME-manual
  $BIN create $OPTS $REPO::$NAME-manual /
}

$CMD

echo "done"
