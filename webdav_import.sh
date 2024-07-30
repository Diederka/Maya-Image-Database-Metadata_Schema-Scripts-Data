#!/usr/bin/bash -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $ROOT/.env

RUBY="/usr/local/rbenv/shims/ruby"
TS=$(date +'%Y%m%d_%H%M%S')
WEBDAV="/var/storage/host/kor/webdav"
CURRENT="$WEBDAV/archive/$TS"

# make sure no previous run is active
if [ ! -f $WEBDAV/done.txt ]; then
  echo 'a previous run has not finished yet'
  exit 1
fi
rm $WEBDAV/done.txt

echo 'waiting to let webdav clients catch up ...'
sleep 5
echo 'done'

# prepare directories
mkdir -p $WEBDAV/archive
mv $WEBDAV/new $CURRENT || mkdir $CURRENT
mkdir -p $WEBDAV/new

# some checks
if ! test -f $CURRENT/data.csv ; then
  echo "$CURRENT/data.csv couldn't be found" >> $CURRENT/log.txt
  exit 1
fi
if ! test -d $CURRENT/images ; then
  echo "$CURRENT/images couldn't be found" >> $CURRENT/log.txt
  exit 1
fi

chown -R www-data: $WEBDAV/new
chown -R app: $CURRENT

# set parameters for import script
export SIMULATION="false"
export DO_ENTITIES="true"
export IMAGES_DIR="$CURRENT/images"
export CSV_FILE="$CURRENT/data.csv"
export RAILS_ENV="production"

# run the import
cd /var/storage/host/kor/current
sudo -u app $RUBY $ROOT/import_All_2021.rb &>> $CURRENT/log.txt

# clean up
touch $WEBDAV/done.txt

chown app: $CURRENT/log.txt
chown app: $WEBDAV/done.txt
