We provide 

Our application profile (metadata schema and documentation).  

And an example of an initial import-csv-file. 

Also a ruby script for initial import for the entities and relationships for our Maya Image Database 
is stored here. It comprises all import scripts for hepling to import the Entities, Properties and Relations, that can be found in our excel-source-Files. The import scripts were created as workaround to mass ingest data 
from our excel tables into our ConedaKOR based web database. 

Also an example-cvs is given which contains the respective colums that are importable via the given script (see archive). 

Also informations about our OAI-API are given here (see archive). 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [General](#general)
- [How to change this code](#how-to-change-this-code)
- [Autoupload via Webdav](#autoupload-via-webdav)
- [Deploy static content via Webdav](#deploy-static-content-via-webdav)
- [Taking snaphots (snapshot.sh)](#taking-snaphots-snapshotsh)
- [Restoring snapshots](#restoring-snapshots)
- [Importing from CSV (import_All_2020.rb)](#importing-from-csv-import_all_2020rb)
- [Check for relationship duplicates (relationship_duplicates.rb)](#check-for-relationship-duplicates-relationship_duplicatesrb)
- [Validate directed relationships (directed_relationship_check.rb)](#validate-directed-relationships-directed_relationship_checkrb)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## General

Log in to the server as user 'kor'. Don't use sudo for any of the steps. The
scripts call sudo on their own, if super user privileges are required.

Please run all scripts from within the script.git clone directory, so before
running a script, first do

~~~bash
cd /home/kor/scripts.git
~~~

Some scripts need configuration, for example database passwords. This can be
changed in the .env file. You can find documentation for the various settings
in .env.example. The values need to be changed only when new scripts are added
with new functionality requiring new configuration options.

Examples:

~~~bash
sh snapshot.sh # for shell scripts
ruby relationship_duplicates.rb # for ruby scripts
~~~

## How to change this code

Make changes to the scripts as needed, then commit and push them to github.
Then make sure to pull those changes to the production server:

~~~bash
cd /home/kor/scripts.git
git pull
~~~

## Autoupload via Webdav

The steps below can be automated without a SSH session to the server. To trigger
This, do the following:

* login to davs://classicmayan.kor.de.dariah.eu/webdav with your Webdav client
  using your credentials
* upload a file `data.csv` to the `new` folder
* upload a directory with images so that the images are then within `new/images`
* to trigger the import, upload an empty file `start.txt` to the `new` folder
  (**IMPORTANT**: do not upload this together with the data and images because
  it could be uploaded first, triggering the import without the data)
* the data is then immediately moved from `new` to a timestamp folder within the
  `archive` folder

The process will then import this data like this:

* a ConedaKOR snapshot is created
* your uploaded data is moved to a timestamp directory within the `archive`
  folder
* the `import_All_2020.rb` script is run on the moved data
* a log file `log.txt` is created within the timestamp directory
* when finished, the process creates the file done.txt in the webdav root folder

Note: This repository contains the systemd units to trigger the script when the
`start.txt` file is created. These were activated like this:

~~~bash
sudo systemctl link /home/kor/scripts.git/kor-webdav.service
sudo systemctl enable /home/kor/scripts.git/kor-webdav.path
~~~

The latter command complains about a missing `Install` section but activates
the unit anyhow.

## Deploy static content via Webdav

Static content (images, videos, css, html etc.) can be made available publicly
by uploading it to the `static/` directory within the webdav (see above). For
example, an image `static/images/mypic.png` is then available at

    https://classicmayan.kor.de.dariah.eu/static/images/mypic.png

Take note that there is no `/webdav/` in this url. To get an overview of
deployed content and to copy urls, you may use

    https://classicmayan.kor.de.dariah.eu/static


## Taking snaphots (snapshot.sh)

~~~bash
sh snapshot.sh
~~~

The script will create a directory for the current timestamp within the
snapshots directory. Taking a snapshot can take some time.

## Restoring snapshots

Before you do this, it might be a good idea to create another snapshot, see
above.

Snapshots are saved in `/home/kor/backups`. Each subdirectory represents one
snapshot. Choose a snapshot to restore and then (we will use 20200313_003812
as example here):

~~~bash
# stop the bg process
cd /home/kor/kor
RAILS_ENV=production bundle exec bin/delayed_job stop

cd /home/kor
# this will take a couple of minutes
cp -a backups/20200313_003812/shared ./SHARED.snapshot
sudo systemctl stop httpd
# this will ask for a password, you can find it in SHARED/database.yml
zcat backups/20200313_003812/dump.sql.gz | mysql -u kor -p kor_production

# move the data from before the restore to the old directory, make sure to add
# an index not to overwrite other old versions. You may also simply delete older
# versions in ./old/SHARED
mv SHARED ./old/SHARED.old7

mv SHARED.snapshot SHARED
sudo systemctl start httpd

# start the bg process
cd /home/kor/kor
RAILS_ENV=production bundle exec bin/delayed_job start

# refresh the index
cd /home/kor/kor
RAILS_ENV=production bundle exec bin/kor index-all
~~~

## Importing from CSV (import_All_2020.rb)

~~~bash
cd /home/kor/kor # this script has to be run from the kor install directory
ruby import_All_2020.rb
~~~

Data is imported from `/home/kor/sourceFiles/source_import.csv` which is a 
hardcoded path for the moment. So is the ConedaKOR install directory
`/home/kor/kor`, `SIMULATION` mode and `DO_ENTITIES`, see top of
`import_All_2020.rb`. Change those settings before running script to match your
needs.

## Check for relationship duplicates (relationship_duplicates.rb)

~~~bash
ruby relationship_duplicates.rb
~~~

This finds and deletes relationship duplicates. Per default, it is in simulation
mode (no data is changed), change this by setting `SIMULATION = false` at the
top of the script.

## Validate directed relationships (directed_relationship_check.rb)

~~~bash
ruby directed_relationship_check.rb
~~~

This verifies the internal structure of directed relationships according to  two
way relationships and corrects potential errors. Per default, it is in
simulation mode (no data is changed), change this by setting `SIMULATION =
false` at the top of the script.
