We provide 

Our application profile (metadata schema and documentation).  

And an example of an initial import-csv-file. 

Also a ruby script for initial import for the entities and relationships for our Maya Image Database 
is stored here. It comprises all import scripts for hepling to import the Entities, Properties and Relations, that can be found in our excel-source-Files. The import scripts were created as workaround to mass ingest data 
from our excel tables into our ConedaKOR based web database. 

Also an example-cvs is given which contains the respective colums that are importable via the given script (see archive). 

Also informations about our OAI-API are given here (see archive). 

## General

Please run all scripts from within the ConedaKOR installation directory, so
e.g.:

~~~bash
cd /home/kor/kor
ruby /home/kor/scripts.git/import_All_2020.rb
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
* upload a directory with images as `images` to the `new` folder
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

## Taking snaphots (snapshot.sh)

Configuration happens within the `.env` file, see `.env.example` for a template
and availabe options.

Run the script with `./snapshot.sh` which will create a directory for the
current timestamp within the snapshots directory. Taking a snapshot can take
some time.

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
cp -a backups/20200313_003812/SHARED ./SHARED.snapshot
sudo systemctl stop httpd
# this will ask for a password, you can find it in SHARED/database.yml
zcat backups/20200313_003812/dump.sql.gz | mysql -u kor -p kor_production
sudo systemctl start httpd

# start the bg process
cd /home/kor/kor
RAILS_ENV=production bundle exec bin/delayed_job start

# refresh the index
cd /home/kor/kor
RAILS_ENV=production bundle exec bin/kor index-all
~~~

## Importing from CSV (import_All_2020.rb)

Data is imported from `/home/kor/sourceFiles/source_import.csv` which is a 
hardcoded path for the moment. So is the ConedaKOR install directory
`/home/kor/kor`, `SIMULATION` mode and `DO_ENTITIES`, see top of
`import_All_2020.rb`. Change those settings before running script to match our
needs.

## Check for relationship duplicates (relationship_duplicates.rb)

This finds and deletes relationship duplicates. Per default, it is in simulation
mode (no data is changed), change this by setting `SIMULATION = false` at the
top of the script.

## Validate directed relationships (directed_relationship_check.rb)

This verifies the internal structure of directed relationships according to  two
way relationships and corrects potential errors. Per default, it is in
simulation mode (no data is changed), change this by setting `SIMULATION =
false` at the top of the script.