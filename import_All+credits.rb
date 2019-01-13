# import scripts for data ingest via database backend
# Authors: Maximilian Broduhn and Katja Diederichs, 2018 - 2019


############################## Import all Entities #####################################
KOR_ROOT="/home/kor/kor/"

# loading the rails environment

require "#{KOR_ROOT}/config/environment"
require 'json'
require 'dimensions'

default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'medium').first

imageNotFound = []

# data ingest via excel (and static values)
File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")

  if(File.file?("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg"))
    width = Dimensions.width("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg")
    height = Dimensions.height("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg")
    end

  jsonData = "{\"image_no\" : \"" + fields[1] + "\",

\"image_width\" : \"" + width.to_s + "\",
\"image_height\" : \"" + height.to_s + "\",

\"image_description\" : \"" + fields[2] + "\",
\"folder_no\" : \"" + fields[0] + "\",
\"license\" : \"" + fields[4] + "\",
\"creator\" : \"" + fields[22] + "\",
\"date_time_created\" : \"" + fields[3] + "\",
\"note\" : \"" + fields[21] + "\",
\"file_name\" : \"" + fields[1] + "\",

\"contributor\" : \"Project Text Database and Dictionary of Classic Mayan\",
\"rights_holder\" : \"Karl Herbert Mayer\",
\"publisher\" : \"Maya Image Archive\",

\"source_type\" : \"Filmstrip\",
\"source_x_dimension_unit\" : \"mm\",
\"source_y_dimension_unit\" : \"mm\",
\"master_image_file_type\" : \"Tiff\",

\"digitized_by\" : \"Project Text Database and Dictionary of Classic Mayan\",
\"date_of_digitization\" : \"2017\",
\"color_space\" : \"RGB\",
\"scanner_model_number\" : \"5000\",
\"scanner_model_name\" : \"Nikon Coolscan 5000 ED\",
\"scanning_software_name\" : \"HDR SilverFast Soft\",
\"scanning_software_version_no\" : \"HDR SilverFast Soft\",

\"medium_depicts_artefact\" : \"" + fields[13] + "\",
\"medium_was_created_by_person\" : \"" + fields[22] + "\",
\"medium_was_created_from_collection\" : \"" + fields[23] + "\",
\"medium_was_created_at_place\" : \"" + fields[5] + "\"}"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  if(File.file?("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg"))
    
    work = Entity.new(
      :kind => document,
      :medium => Medium.new(document: File.open("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg")),
      :collection => default,
      :dataset => jsonObj,
      :distinct_name => fields[1],
      :datings => [
        EntityDating.new(label: "Year", dating_string: fields[3])
      ]
      )
      if work.valid?
        p work
        work.save
      else
        p work
        p work.errors.full_messages
      end
  else
      puts "Bilddatei nicht gefunden"
      imageNotFound << fields[1]
  end
end

for image in imageNotFound
  puts image
end





default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Artefact').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")

  jsonData = "{
  \"artefact_type\" : \"" + fields[14] + "\",
  \"artefact_type_in_twkm_database\" : \"" + fields[15] + "\",
  \"artefact_in_twkm_database\" : \"" + fields[16] + "\",
  \"catalog_no\" : \"" + fields[17] + "\",
  \"artefact_publication\" : \"" + fields[18] + "\",
  \"artefact_publication_zotero\" : \"" + fields[19] + "\",
  \"inventory_no\" : \"" + fields[20] + "\",
  \"artefact_is_depicted_by_medium\" : \"" + fields[1] + "\",
  \"artefact_was_located_in_place\" : \"" + fields[5] + "\",
  \"artefact_originates_from_provenance\" : \"" + fields[9] + "\",
  \"artefact_was_documented_by_person\" : \"" + fields[22] + "\",
  \"artefact_was_held_by_collection\" : \"" + fields[23] + "\"
}"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[13],
  # :distinct_name => fields[],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end





default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Collection').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")

  jsonData = "{
\"collection_was_held_by_holder\" : \"" + fields[7] + "\",
\"collection_held_artefact\" : \"" + fields[13] + "\",
\"collection_was_located_in_place\" : \"" + fields[5] + "\",
\"collection_from_where_medium_was_created\" : \"" + fields[1] + "\"}"
  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[23],
  # :distinct_name => fields[],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end





default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Person').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")
  jsonData = "{
\"person_created_medium\" : \"" + fields[1] + "\",
\"person_documented_artefact\" : \"" + fields[13] + "\",
\"person_visited place\" : \"" + fields[5] + "\"
}"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[22],
   #:distinct_name => fields[],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end





default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Place').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")
 puts fields[24]
  jsonData = "{\"place_in_twkm_database\" : \"" + fields[6] + "\",
 \"place_located_holder\" : \"" + fields[7] + "\",
 \"place_located_artefact\" : \"" + fields[13] + "\",
 \"place_was_visited_by_person\" : \"" + fields[22] + "\",
 \"place_located_collection\" : \"" + fields[23] + "\",
 \"place_where_medium_was_created\" : \"" + fields[1] + "\"
}"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[5],
  # :distinct_name => fields[],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end





default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Provenance').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")
  jsonData = "{
  \"provenance_in_twkm_website\" : \"" + fields[11] + "\",
  \"provenance_in_twkm_database\" : \"" + fields[12] + "\",
  \"provenance_is_origin_of_artefact\" : \"" + fields[13] + "\"
  }"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[9],
    :distinct_name => fields[10],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end






default = Collection.where(:name => 'Guest Collection').first
document = Kind.where(:name => 'Holder').first

File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
  fields = line.split(";")
  jsonData = "{
  \"holder_in_twkm_website\" : \"" + fields[8] + "\",
  \"holder_held_collection\" : \"" + fields[23] + "\",
  \"holder_was_located_in_place\" : \"" + fields[5] + "\"
  }"

  jsonObj = JSON.parse(jsonData)
  puts jsonData

  work = Entity.new(
    :kind => document,
    :collection => default,
    :name => fields[7],
 # :distinct_name => fields[],
    :dataset => jsonObj
  )

  if work.valid?
    p work
    work.save
  else
    p work
    p work.errors.full_messages
  end
end




############################## Import their Relations #####################################



default = Collection.where(:name => 'default').first
place = Kind.where(:name => 'Place').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  artefact.entities.each do |artefact_entity|
    place.entities.where(:name => artefact_entity.dataset['artefact_was_located_in_place']).each do |place_entity|
      puts "SUCCESS"
      unless Relationship.related?(artefact_entity, "artefact was located in place", place_entity)
        Relationship.relate_and_save(artefact_entity, "artefact was located in place", place_entity)
      end
    end
  end
puts "Finished artefact_was_located_in_place"




default = Collection.where(:name => 'default').first
artefact = Kind.where(:name => 'Artefact').first
place = Kind.where(:name => 'Place').first

relationship =
  place.entities.each do |place_entity|
    artefact.entities.where(:name => place_entity.dataset['place_located_artefact']).each do |artefact_entity|
    puts "SUCCESS"
    unless Relationship.related?(place_entity, "place located artefact", artefact_entity)
      Relationship.relate_and_save(place_entity, "place located artefact", artefact_entity)
    end
  end
end
puts "Finished place_located_artefact"



default = Collection.where(:name => 'default').first
provenance = Kind.where(:name => 'Provenance').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  artefact.entities.each do |artefact_entity|
    provenance.entities.where(:name => artefact_entity.dataset['artefact_originates_from_provenance']).each do |provenance_entity|
      puts "SUCCESS"
      unless Relationship.related?(artefact_entity, "artefact originates from provenance", provenance_entity)
        Relationship.relate_and_save(artefact_entity, "artefact originates from provenance", provenance_entity)
      end
    end
  end
puts "Finished artefact_originates_from_provenance"




default = Collection.where(:name => 'default').first
collection = Kind.where(:name => 'Collection').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  artefact.entities.each do |artefact_entity|
    collection.entities.where(:name => artefact_entity.dataset['artefact_was_held_by_collection']).each do |collection_entity|
      puts "SUCCESS"
      unless Relationship.related?(artefact_entity, "artefact was held by collection", collection_entity)
        Relationship.relate_and_save(artefact_entity, "artefact was held by collection", collection_entity)
      end
    end
  end
puts "Finished artefact_was_held_by_collection"




default = Collection.where(:name => 'default').first
place = Kind.where(:name => 'Place').first
medium = Kind.where(:name => 'Medium').first

relationship =
  medium.entities.each do |medium_entity|
    place.entities.where(:name => medium_entity.dataset['medium_was_created_at_place']).each do |place_entity|
      puts "SUCCESS"
      unless Relationship.related?(medium_entity, "medium was created at place", place_entity)
        Relationship.relate_and_save(medium_entity, "medium was created at place", place_entity)
      end
    end
  end
puts "Finished medium_was_created_at_place"





default = Collection.where(:name => 'default').first
collection = Kind.where(:name => 'Collection').first
place = Kind.where(:name => 'Place').first

relationship =
  place.entities.each do |place_entity|
    collection.entities.where(:name => place_entity.dataset['place_located_collection']).each do |collection_entity|
    puts "SUCCESS"
    unless Relationship.related?(place_entity, "place located collection", collection_entity)
      Relationship.relate_and_save(place_entity, "place located collection", collection_entity)
    end
  end
end
puts "Finished place_located_collection"





default = Collection.where(:name => 'default').first
collection = Kind.where(:name => 'Collection').first
medium = Kind.where(:name => 'Medium').first

relationship =
  medium.entities.each do |medium_entity|
    collection.entities.where(:name => medium_entity.dataset['medium_was_created_from_collection']).each do |collection_entity|
      puts "SUCCESS"
      unless Relationship.related?(medium_entity, "medium was created from collection", collection_entity)
        Relationship.relate_and_save(medium_entity, "medium was created from collection", collection_entity)
      end
    end
  end
  puts "Finished medium_was_created_from_collection" 


 
 
 
 
  default = Collection.where(:name => 'default').first
  artefact = Kind.where(:name => 'Artefact').first
  medium = Kind.where(:name => 'Medium').first

  relationship =
    medium.entities.each do |medium_entity|
      artefact.entities.where(:name => medium_entity.dataset['medium_depicts_artefact']).each do |artefact_entity|
        puts "SUCCESS"
        unless Relationship.related?(medium_entity, "medium depicts artefact", artefact_entity)
          Relationship.relate_and_save(medium_entity, "medium depicts artefact", artefact_entity)
        end
      end
    end
  puts "Finished medium_depicts_artefact"





  default = Collection.where(:name => 'default').first
  holder = Kind.where(:name => 'Holder').first
  collection = Kind.where(:name => 'Collection').first

  relationship =
    collection.entities.each do |collection_entity|
      holder.entities.where(:name => collection_entity.dataset['collection_was_held_by_holder']).each do |holder_entity|
      puts "SUCCESS"
        unless Relationship.related?(collection_entity, "collection was held by holder", holder_entity)
          Relationship.relate_and_save(collection_entity, "collection was held by holder", holder_entity)
        end
      end
    end
  puts "Finished collection_was_held_by_holder"

 
 
 
 
  default = Collection.where(:name => 'default').first
  person = Kind.where(:name => 'Person').first
  place = Kind.where(:name => 'Place').first

  relationship =
    place.entities.each do |place_entity|
      person.entities.where(:name => place_entity.dataset['place_was_visited_by_person']).each do |person_entity|
        puts "SUCCESS"
        unless Relationship.related?(place_entity, "place was visited by person", person_entity)
          Relationship.relate_and_save(place_entity, "place was visited by person", person_entity)
        end
      end
    end
  puts "Finished place_was_visited_by_person"





  default = Collection.where(:name => 'default').first
  holder = Kind.where(:name => 'Holder').first
  place = Kind.where(:name => 'Place').first

  relationship =
    place.entities.each do |place_entity|
      holder.entities.where(:name => place_entity.dataset['place_located_holder']).each do |holder_entity|
        puts "SUCCESS"
        unless Relationship.related?(place_entity, "place located holder", holder_entity)
          Relationship.relate_and_save(place_entity, "place located holder", holder_entity)
        end
      end
    end
  puts "Finished place_located_holder"





  default = Collection.where(:name => 'default').first
  person = Kind.where(:name => 'Person').first
  medium = Kind.where(:name => 'Medium').first

  relationship =
    medium.entities.each do |medium_entity|
      person.entities.where(:name => medium_entity.dataset['medium_was_created_by_person']).each do |person_entity|
        puts "SUCCESS"
        unless Relationship.related?(medium_entity, "medium was created by person", person_entity)
          Relationship.relate_and_save(medium_entity, "medium was created by person", person_entity)
        end
      end
    end
  puts "Finished medium_was_created_by_person"





  default = Collection.where(:name => 'default').first
  person = Kind.where(:name => 'Person').first
  artefact = Kind.where(:name => 'Artefact').first

  relationship =
    artefact.entities.each do |artefact_entity|
      person.entities.where(:name => artefact_entity.dataset['artefact_was_documented_by_person']).each do |person_entity|
        puts "SUCCESS"
        unless Relationship.related?(artefact_entity, "artefact was documented by person", person_entity)
          Relationship.relate_and_save(artefact_entity, "artefact was documented by person", person_entity)
        end
      end
    end
  puts "Finished artefact_was_documented_by_person"
  
  puts "Finished all!!!!!!!"
  
=begin
  Otto the Open Access Otter says "Goodbye!"
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ &(///@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#/////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/(@%/////%    ,#////////((//////@&@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//%@///(*       /////@     /(/////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////&     @@&////(.    @@&//////@//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////@     &//////@     *//////@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////////////////@@@////////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ &/////////////////////////////////@(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////@&%%&&&@@///////////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////@%#%&&&&&&@///////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///**.  ,,*///@&&&&&&&&@(////****///(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//*      .,*///#@@&&@@(/////*.    ,/(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @/*      @.  ..,.  @ .,////*.  @,  .*&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,     , @       *&,         .%@   ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,         %@@&,    (@@@@@&,      .(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#@@@@@@@@@@@@@@@@@@@@@@ #,.                            .,%,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#///@@@@@@@@@@@@@@@@@@@@@@@(,.                          .*%  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////@@@@@@@@@@@@@@@@@@@@@@@@*,                       .,%  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&//%///@@@@@@@@@@@@@@@@@@@@@@@@@#,                     ,#, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#///#//(&&%%@@@@@@@@@@@@@@@@@@@@@@*.                   ,( @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///#////(//////@@@@@@@@@@@@@@@@@@@,*/.                  .*@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%///////////////%@@@@@@@@@@@@@@@@/,(%/,                  **/,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%(////////#@@@@@@@@@@@@@@@@@@#,**//.                 ,*/(**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&////////(@@@@@@@@@@@@@@@@@@@@@,,**                 ,*///,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////&@@@@@@@@@@@@@@@@@@@///,*                ,*/**/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////%@@@@@@@@@@@@@@@@@@///*,,,**************,,,,//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((////(@@@@@@@@@@@@@@@@@////,***#((#(((,......*,,,//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////@@@@@@@@@@@@@@@@@///****(#*****/******,.,,,//%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////@@@@@@@@@@@@@@@@&%//*,**(**************.,,,////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////@@@@@@@@@@%(///////*,**/(((OA((..,**,,.,,,///////(&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##///////////////////////*,*************,,**,,,,////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%///////////////////////*,**//((((/*,,,,,.,.,,,//////////////&(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(%///////////////(#%%////,,,,******,,,,,,,,,,,*///%(///////////#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%//////(%%%/@@@@@//////*.      .....   ,**//////(&@%&%#////////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(//////*               ,*///////(@@@@@@@%//////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&//////*,               ,*////////&@@@@@@@%/////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////*.               ,*///////(&@@@@@@#//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&///////*,                .*///////(%@@@@@(//////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(//////*,.                .,*//////(&@@@@%//////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(&///////*,                 .,*///////@@@@%//////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////*,                   ,*///////@@@///////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////*,.                   ,*///////@@//////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&///////**.                    ,*///////@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&///////**,                    .*////////%////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(//////**,                     .*////////#/////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(//////**,                      ,*////////@////#%(#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////**,                       ,*////////%@//////(,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////*,.                       .*/////////@@&(///%(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#///////*,.                        ,*/////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////,.                        .*//////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////////*,                        .,*/////////%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&//////////*.                        ,*//////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#///////////*.                       ,*///////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&////////////*.                     .**///////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////,                   .,*/////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////*,               ..,*//////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////////////////*,.        ..,**///////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@/////////////////////*******///////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///@/////////////////////////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/////@///(//////////////////////////////////////&(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@////////@/%///////////////////////////////&@////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////@#//////#@(////////////////&@/////@//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(//////////#@@@///////@//////////////////@/////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&///////////@@@@@///////@&///////////////#@@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%////////////@@@@@@//////(/@@@@@@@@@@@@@@@@@@@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(////////////@@@@@@@&//////@@@@@@@@@@@@@@@@@@@@@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%/////////////@@@@@@@@@//////@@@@@@@@@@@@@@@@@@@@@@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////@@@@@@@@@#//////@@@@@@@@@@@@@@@@@@@@@@%//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&//////////////@@@@@(@@//////////@@@@@@@@@@@@@@@@@@@@@@@////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@%///////////////@@@@@@@/////////////@@@@@@@@@@@@@@@@@@@@@@@@/////////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@(/////////////////#@@@@@@@@/////////////@@@@@@@@@@@@@@@@@@@@@@@@@@////////////&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@&//////////////////////@@@@@@@@@@@(////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@#///////////////////////(@@@@@@@@@@@@@@@@////@////////@@@@@@@@@@@@@@@@@@@@@@@@@@@/////&//@//////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@&(////////////(#%@@@@@@@@@@@@@@@@@@@@@@@@@%//@//&/////#@@@@@@@@@@@@@@@@@@@@@@@@@//////@///#/////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Otto the Open Access Otter by Katja Diederichs 2018 @@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ created with ASCII Art Converter @@@@@@@@@@@@@@@@@@@
=end
