#!/bin/bash -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RUBY="/usr/local/rvm/rubies/ruby-2.5.7/bin/ruby"
TS=$(date +'%Y%M%D_%H%M%S')
WEBDAV="/home/kor/SHARED/webdav"
CURRENT="$WEBDAV/archive/$TS"

# make sure no previous run is active
if ! -f $WEBDAV/done.txt ; then
  echo 'a previous run has not finished yet' >> $CURRENT/log.txt
  exit 1
fi
rm $WEBDAV/done.txt

# prepare directories
mkdir -p $WEBDAV/archive
mv $WEBDAV/new $CURRENT
mkdir -p $WEBDAV/new
sudo chown apache. $WEBDAV/new
sudo chown kor. $CURRENT

# some checks
if ! -f $CURRENT/data.csv ; then
  echo "$CURRENT/data.csv couldn't be found" >> $CURRENT/log.txt
  exit 1
fi
if ! -d $CURRENT/images ; then
  echo "$CURRENT/images couldn't be found" >> $CURRENT/log.txt
  exit 1
fi

# set parameters for import script
export KOR_ROOT="/home/kor/kor"
export SIMULATION="true"
export DO_ENTITIES="true"
export IMAGES_DIR="$CURRENT/images"
export CSV_FILE="$CURRENT/data.csv"

# make a backup
/home/kor/scripts.git/snapshot.sh &>> $CURRENT/log.txt

# run the import
sudo -u kor $RUBY $ROOT/import_ALL_2020.rb &>> $CURRENT/log.txt

# clean up
sudo -u kor touch $WEBDAV/done.txt
