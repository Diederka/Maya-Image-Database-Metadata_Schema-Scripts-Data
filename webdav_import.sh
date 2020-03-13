#!/bin/bash -e

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $ROOT/.env

RUBY="/usr/local/rvm/wrappers/ruby-2.5.7/ruby"
TS=$(date +'%Y%m%d_%H%M%S')
WEBDAV="/home/kor/kor/webdav"
CURRENT="$WEBDAV/archive/$TS"

# make sure no previous run is active
if ! test -f $WEBDAV/done.txt ; then
  echo 'a previous run has not finished yet'
  exit 1
fi
rm $WEBDAV/done.txt

# prepare directories
mkdir -p $WEBDAV/archive
mv $WEBDAV/new $CURRENT || mkdir $CURRENT
mkdir -p $WEBDAV/new
sudo chown apache. $WEBDAV/new
sudo chown kor. $CURRENT

# some checks
if ! test -f $CURRENT/data.csv ; then
  echo "$CURRENT/data.csv couldn't be found" >> $CURRENT/log.txt
  exit 1
fi
if ! test -d $CURRENT/images ; then
  echo "$CURRENT/images couldn't be found" >> $CURRENT/log.txt
  exit 1
fi

# set parameters for import script
export SIMULATION="true"
export DO_ENTITIES="true"
export IMAGES_DIR="$CURRENT/images"
export CSV_FILE="$CURRENT/data.csv"

# make a backup
/home/kor/scripts.git/snapshot.sh &>> $CURRENT/log.txt

# run the import
$RUBY $ROOT/import_All_2020.rb &>> $CURRENT/log.txt

# clean up
touch $WEBDAV/done.txt
