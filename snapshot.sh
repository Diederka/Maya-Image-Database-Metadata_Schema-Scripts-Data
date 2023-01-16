#!/bin/bash -e

CMD=${1:-manual}
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $ROOT/.env
REPO="$BACKUP_DIRECTORY/borg"

DATA_DIR="/home/kor/rack"
BIN="/usr/bin/borg"
OPTS="--compression none -v --show-rc --progress --info --stats"
DATA_SPEC="$DATA_DIR/shared"
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

# ensure db dump is up to date
function ensure_dump {
  # sudo systemctl stop httpd
  mysqldump -u root -p"$MYSQL_PASSWORD" kor_production | gzip -c > $KOR_SHARED/dump.sql.gz
  # sudo systemctl start httpd
}

function init {
  $BIN init --encryption none $REPO
}

function list {
  $BIN list -v $REPO
}

function info {
  $BIN info $REPO
}

function provide {
  TARGET="/home/kor/backups/borg.latest/"
  LATEST=$($BIN list --short $REPO | tail -n 1)

  $BIN export-tar $REPO::$LATEST $TARGET/.kor.tar.gz.tmp
  mv $TARGET/.kor.tar.gz.tmp $TARGET/kor.tar.gz
  chmod +r $TARGET/kor.tar.gz
}

function nightly {
  ensure_dump

  # do the backup and clean up
  $BIN create $OPTS $REPO::nightly-{now:%Y%m%d_%H%M%S} $DATA_SPEC
  $BIN prune -v --list --keep-daily=30 --keep-weekly=8 --keep-monthly=24 --prefix=nightly $REPO

  # provide latest snapshot for download
  provide
}

function manual {
  ensure_dump

  # $BIN delete $REPO::$NAME-manual $DATA_SPEC
  $BIN create $OPTS $REPO::manual-{now:%Y-%m-%d-%H-%M-%S} $DATA_SPEC
  echo "done"
}

$CMD
