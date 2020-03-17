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

## Autoupload via Webdav

The steps below can be automated without a SSH session to the server. To trigger
This, do the following:

* login to davs://classicmayan.kor.de.dariah.eu/webdav with your Webdav client
  using your credentials
* upload a file `data.csv` to the `new` folder
* upload a directory with images as `images` to the `new` folder
* to trigger the import, upload an empty file `start.txt` to the `new` folder
  (IMPORTANT: do not upload this together with the data and images because it
  could be uploaded first, triggering the import without the data)

The process will then import this data like this:

* a ConedaKOR snapshot is created
* your uploaded data is moved to a timestamp directory within the `archive`
  folder
* the `import_All_2020.rb` script is run on the moved data
* a log file `log.txt` is created within the timestamp directory
* when finished, the process creates the file done.txt in the webdav root folder

## Taking snaphots (snapshot.sh)

Configuration happens within the `.env` file, see `.env.example` for a template
and availabe options.

Run the script with `./snapshot.sh` which will create a directory for the
current timestamp within the snapshots directory. Taking a snapshot can take
some time.

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