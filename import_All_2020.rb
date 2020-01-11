# import scripts for data ingest via database backend
# Authors: Maximilian Brodhun, Katja Diederichs and Moritz Schepp, 2018 - 2019

# new: 08.2019: culture and culture_in_aat get static values 


############################## Import all Entities #####################################
KOR_ROOT="/home/kor/kor"
SIMULATION=true
DO_ENTITIES=true

puts "SIMULATION MODE" if SIMULATION

# helper methods

# get image dimensions
# @param path [String] the path to the file
# @return [Integer, Integer] the image dimensions
def dimensions_for(path)
  return nil unless File.file?(path)

  r, w = IO.pipe
  pid = Process.spawn('identify', '-format', "%wx%h", path, out: w, err: '/dev/null')
  w.close
  pid, status = Process.wait2(pid)

  status == 0 ? r.read.split('x').map{|e| e.to_i} : nil
end

# loading the rails environment

require "#{KOR_ROOT}/config/environment"
require 'json'
# require 'pry'
#require 'dimensions'

if DO_ENTITIES
  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'medium').first

  imageNotFound = []

  # data ingest via excel (and static values)
  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

    # size=[]
    # dimensions=''
    # if(File.file?("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg"))
    #    filename = "/home/kor/IMAGESinJPG/" + fields[1] + ".jpg"
    #    if !(filename.include? "(")
    #        size = `identify #{filename} -format '%wx%h'`.split('x')
    #    end
    # end
    # if size.length > 0
    #   dimensions = size[1]
    # end
    dimensions = dimensions_for("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg")
    dimensions = (dimensions ? dimensions[1].to_s : '')

    mwcfc=''

    if (fields[23].nil?)
      mwcfc =''
    else
      mwcfc = fields[23]
    end

  #   jsonData = "{\"image_no\" : \"" + fields[1] + "\",

  # \"image_dimensions\" : \"" + dimensions  + "\",

  # \"image_description\" : \"" + fields[2] + "\",
  # \"folder_no\" : \"" + fields[0] + "\",
  # \"license\" : \"" + fields[4] + "\",
  # \"creator\" : \"" + fields[22] + "\",
  # \"date_time_created\" : \"" + fields[3] + "\",
  # \"note\" : \"" + fields[21] + "\",
  # \"file_name\" : \"" + fields[1] + "\",

  # \"contributor\" : \"Project Text Database and Dictionary of Classic Mayan\",
  # \"rights_holder\" : \"Karl Herbert Mayer\",
  # \"publisher\" : \"Maya Image Archive\",

  # \"source_type\" : \"Filmstrip\",
  # \"source_x_dimension_unit\" : \"mm\",
  # \"source_y_dimension_unit\" : \"mm\",
  # \"master_image_file_type\" : \"Tiff\",

  # \"digitized_by\" : \"Project Text Database and Dictionary of Classic Mayan\",
  # \"date_of_digitization\" : \"2017\",
  # \"color_space\" : \"RGB\",
  # \"scanner_model_number\" : \"5000\",
  # \"scanner_model_name\" : \"Nikon Coolscan 5000 ED\",
  # \"scanning_software_name\" : \"HDR SilverFast Soft\",
  # \"scanning_software_version_no\" : \"HDR SilverFast Soft\",

  # \"medium_depicts_artefact\" : \"" + fields[13] + "\",
  # \"medium_was_created_by_person\" : \"" + fields[22] + "\",
  # \"medium_was_created_from_collection\" : \"" + mwcfc + "\",
  # \"medium_was_created_at_place\" : \"" + fields[5] + "\"}"

  #   jsonObj = JSON.parse(jsonData)
    # puts jsonData

    jsonObj = {
      'image_no' => fields[1],

      'image_dimensions' => dimensions,

      'image_description' => fields[2],
      'folder_no' => fields[0],
      'license' => fields[4],
      'creator' => fields[22],
      'date_time_created' => fields[3],
      'note' => fields[21],
      'file_name' => fields[1],

      'contributor' => "Project Text Database and Dictionary of Classic Mayan",
      'rights_holder' => "Karl Herbert Mayer",
      'publisher' => "Maya Image Archive",

      'source_type' => "Filmstrip",
      'source_x_dimension_unit' => "mm",
      'source_y_dimension_unit' => "mm",
      'master_image_file_type' => "Tiff",

      'digitized_by' => "Project Text Database and Dictionary of Classic Mayan",
      'date_of_digitization' => "2017",
      'color_space' => "RGB",
      'scanner_model_number' => "5000",
      'scanner_model_name' => "Nikon Coolscan 5000 ED",
      'scanning_software_name' => "HDR SilverFast Soft",
      'scanning_software_version_no' => "HDR SilverFast Soft",

      'medium_depicts_artefact' => fields[13],
      'medium_was_created_by_person' => fields[22],
      'medium_was_created_from_collection' => mwcfc,
      'medium_was_created_at_place' => fields[5]
    }

    if(File.file?("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg"))
      
      work = Entity.new(
        :kind => document,
        :medium => Medium.new(document: File.open("/home/kor/IMAGESinJPG/" + fields[1] + ".jpg")),
        :collection => default,
        :dataset => jsonObj,
        :distinct_name => fields[1]
      )

      if fields[3].present?
        work.datings << EntityDating.new(label: 'Year', dating_string: fields[3])
      end

      if work.valid?
        # p work
        work.save unless SIMULATION
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
  puts "Finished Medium"

  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Artefact').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

    awhbc=''
    if (fields[23].nil?)
      awhbc =''
    else
      awhbc = fields[23]
    end

  #   jsonData = "{
  #   \"artefact_type\" : \"" + fields[14] + "\",
  #   \"artefact_type_in_twkm_database\" : \"" + fields[15] + "\",
  #   \"artefact_in_twkm_database\" : \"" + fields[16] + "\",
  #   \"catalog_no\" : \"" + fields[17] + "\",
  #   \"artefact_publication\" : \"" + fields[18] + "\",
  #   \"artefact_publication_zotero\" : \"" + fields[19] + "\",
  #   \"inventory_no\" : \"" + fields[20] + "\",
  #   \"artefact_is_depicted_by_medium\" : \"" + fields[1] + "\",
  #   \"artefact_was_located_in_place\" : \"" + fields[5] + "\",
  #   \"artefact_originates_from_provenance\" : \"" + fields[9] + "\",
  #   \"artefact_was_documented_by_person\" : \"" + fields[22] + "\",
  #   \"artefact_was_held_by_collection\" : \"" + awhbc + "\",
  # \"culture\" : \"Maya\",
  # \"culture_in_aat\" : \"300017826\"
  # }"

    jsonObj = {
      'artefact_type' => fields[14],
      'artefact_type_in_twkm_database' => fields[15],
      'artefact_in_twkm_database' => fields[16],
      'catalog_no' => fields[17],
      'artefact_publication' => fields[18],
      'artefact_publication_zotero' => fields[19],
      'inventory_no' => fields[20],
      'artefact_is_depicted_by_medium' => fields[1],
      'artefact_was_located_in_place' => fields[5],
      'artefact_originates_from_provenance' => fields[9],
      'artefact_was_documented_by_person' => fields[22],
      'artefact_was_held_by_collection' => awhbc,
      'culture' => "Maya",
      'culture_in_aat' => "300017826"
    }

    # jsonObj = JSON.parse(jsonData)
    # puts jsonData

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => fields[13].gsub(/ {2,}/, ' '),
    # :distinct_name => fields[],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Artefact"

  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Collection').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

  #   jsonData = "{
  # \"collection_was_held_by_holder\" : \"" + fields[7] + "\",
  # \"collection_held_artefact\" : \"" + fields[13] + "\",
  # \"collection_was_located_in_place\" : \"" + fields[5] + "\",
  # \"collection_from_where_medium_was_created\" : \"" + fields[1] + "\"}"
  #   jsonObj = JSON.parse(jsonData)
  #   puts jsonData

    jsonObj = {
      'collection_was_held_by_holder' => fields[7],
      'collection_held_artefact' => fields[13],
      'collection_was_located_in_place' => fields[5],
      'collection_from_where_medium_was_created' => fields[1]
    }

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => (fields[23] || '').gsub(/ {2,}/, ' '),
    # :distinct_name => fields[],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Collection"

  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Person').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

  #   jsonData = "{
  # \"person_created_medium\" : \"" + fields[1] + "\",
  # \"person_documented_artefact\" : \"" + fields[13] + "\",
  # \"person_visited place\" : \"" + fields[5] + "\"
  # }"
  #   jsonObj = JSON.parse(jsonData)
  #   puts jsonData

    jsonObj = {
      'person_created_medium' => fields[1],
      'person_documented_artefact' => fields[13],
      'person_visited_place' => fields[5]
    }

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => fields[22].gsub(/ {2,}/, ' '),
     #:distinct_name => fields[],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Person"

  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Place').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")
    puts fields[24]

    plc=''
    if (fields[23].nil?)
      plc =''
    else
      plc = fields[23]
    end

  #   jsonData = "{\"place_in_twkm_database\" : \"" + fields[6] + "\",
  #  \"place_located_holder\" : \"" + fields[7] + "\",
  #  \"place_located_artefact\" : \"" + fields[13] + "\",
  #  \"place_was_visited_by_person\" : \"" + fields[22] + "\",
  #  \"place_located_collection\" : \"" + plc + "\",
  #  \"place_where_medium_was_created\" : \"" + fields[1] + "\"
  # }"
  #   jsonObj = JSON.parse(jsonData)
  #   puts jsonData
    
    jsonObj = {
     'place_in_twkm_database' => fields[6],
     'place_located_holder' => fields[7],
     'place_located_artefact' => fields[13],
     'place_was_visited_by_person' => fields[22],
     'place_located_collection' => plc,
     'place_where_medium_was_created' => fields[1]
    }

    # TODO: why not like this?
    # jsonObj = {
    #   'place_in_twkm_database' => fields[6],
    #   'place_located_holder' => fields[7],
    #   'place_located_artefact' => fields[13],
    #   'place_was_visited_by_person' => fields[22],
    #   'place_located_collection' => fields[23],
    #   'place_where_medium_was_created' => fields[1]
    # }

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => fields[5].gsub(/ {2,}/, ' '),
    # :distinct_name => fields[],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Place"

  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Provenance').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

    # jsonData = "{
    # \"provenance_in_twkm_website\" : \"" + fields[11] + "\",
    # \"provenance_in_twkm_database\" : \"" + fields[12] + "\",
    # \"provenance_is_origin_of_artefact\" : \"" + fields[13] + "\"
    # }"
    # jsonObj = JSON.parse(jsonData)
    # puts jsonData
    jsonObj = {
      'provenance_in_twkm_website' => fields[11],
      'provenance_in_twkm_database' => fields[12],
      'provenance_is_origin_of_artefact' => fields[13]
    }

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => fields[9].gsub(/ {2,}/, ' '),
      :distinct_name => fields[10],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Provenance"


  default = Collection.where(:name => 'Guest Collection').first
  document = Kind.where(:name => 'Holder').first

  File.read("/home/kor/sourceFiles/source_import.csv").split("\n")[1..-1].each do |line|
    fields = line.split(";")

    hhc=''
    if (fields[23].nil?)
      hhc =''
    else
      hhc = fields[23]
    end

    # jsonData = "{
    # \"holder_in_twkm_website\" : \"" + fields[8] + "\",
    # \"holder_held_collection\" : \"" + hhc + "\",
    # \"holder_was_located_in_place\" : \"" + fields[5] + "\"
    # }"
    # jsonObj = JSON.parse(jsonData)
    # puts jsonData
    jsonObj = {
      'holder_in_twkm_website' => fields[8],
      'holder_held_collection' => hhc,
      'holder_was_located_in_place' => fields[5]
    }

    work = Entity.new(
      :kind => document,
      :collection => default,
      :name => fields[7].gsub(/ {2,}/, ' '),
   # :distinct_name => fields[],
      :dataset => jsonObj
    )

    if work.valid?
      # p work
      work.save unless SIMULATION
    else
      p work
      p work.errors.full_messages
    end
  end
  puts "Finished Holder"
end


############################## Import their Relations #####################################


default = Collection.where(:name => 'default').first
place = Kind.where(:name => 'Place').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  artefact.entities.each do |artefact_entity|
    place.entities.where(:name => artefact_entity.dataset['artefact_was_located_in_place']).each do |place_entity|
      puts "SUCCESS"
      unless Relationship.related?(artefact_entity, "artefact is / was located in place", place_entity)
        unless SIMULATION
          # TODO: this and all other instances of this might fail validations
          # but still return the (unsaved) relationship
          Relationship.relate_and_save(artefact_entity, "artefact is / was located in place", place_entity)
        end
      end
    end
  end
puts "Finished artefact_was_located_in_place"


default = Collection.where(:name => 'default').first
holder = Kind.where(:name => 'Holder').first
place = Kind.where(:name => 'Place').first

relationship =
  place.entities.each do |place_entity|
    holder.entities.where(:name => place_entity.dataset['place_located_holder']).each do |holder_entity|
      puts "SUCCESS"
      unless Relationship.related?(place_entity, "place locates / located holder", holder_entity)
        unless SIMULATION
          Relationship.relate_and_save(place_entity, "place locates / located holder", holder_entity)
        end
      end
    end
  end
puts "Finished place_located_holder"

default = Collection.where(:name => 'default').first
provenance = Kind.where(:name => 'Provenance').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  artefact.entities.each do |artefact_entity|
    provenance.entities.where(:name => artefact_entity.dataset['artefact_originates_from_provenance']).each do |provenance_entity|
      puts "SUCCESS"
      unless Relationship.related?(artefact_entity, "artefact originates from provenance", provenance_entity)
        unless SIMULATION
          Relationship.relate_and_save(artefact_entity, "artefact originates from provenance", provenance_entity)
        end
      end
    end
  end
puts "Finished artefact_originates_from_provenance"

default = Collection.where(:name => 'default').first
collection = Kind.where(:name => 'Collection').first
artefact = Kind.where(:name => 'Artefact').first

relationship =
  collection.entities.each do |collection_entity|
    artefact.entities.where(:name => collection_entity.dataset['collection_held_artefact']).each do |artefact_entity|
      puts "SUCCESS"
      unless Relationship.related?(collection_entity, "collection holds / held artefact", artefact_entity)
        unless SIMULATION
          Relationship.relate_and_save(collection_entity, "collection holds / held artefact", artefact_entity)
        end
      end
    end
  end
puts "Finished collection_held_artefact"

default = Collection.where(:name => 'default').first
place = Kind.where(:name => 'Place').first
medium = Kind.where(:name => 'Medium').first

relationship =
  medium.entities.each do |medium_entity|
    place.entities.where(:name => medium_entity.dataset['medium_was_created_at_place']).each do |place_entity|
      puts "SUCCESS"
      unless Relationship.related?(medium_entity, "medium was created at place", place_entity)
        unless SIMULATION
          Relationship.relate_and_save(medium_entity, "medium was created at place", place_entity)
        end
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
      unless Relationship.related?(place_entity, "place locates / located collection", collection_entity)
        unless SIMULATION
          Relationship.relate_and_save(place_entity, "place locates / located collection", collection_entity)
        end
      end
    end
  end
puts "Finished"

default = Collection.where(:name => 'default').first
collection = Kind.where(:name => 'Collection').first
medium = Kind.where(:name => 'Medium').first

relationship =
  medium.entities.each do |medium_entity|
    collection.entities.where(:name => medium_entity.dataset['medium_was_created_from_collection']).each do |collection_entity|
      puts "SUCCESS"
      unless Relationship.related?(medium_entity, "medium was created from collection", collection_entity)
        unless SIMULATION
          Relationship.relate_and_save(medium_entity, "medium was created from collection", collection_entity)
        end
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
          unless SIMULATION
            Relationship.relate_and_save(medium_entity, "medium depicts artefact", artefact_entity)
          end
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
      unless Relationship.related?(collection_entity, "collection is / was held by holder", holder_entity)
        unless SIMULATION
          Relationship.relate_and_save(collection_entity, "collection is / was held by holder", holder_entity)
        end
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
          unless SIMULATION
            Relationship.relate_and_save(place_entity, "place was visited by person", person_entity)
          end
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
        unless Relationship.related?(place_entity, "place locates / located holder", holder_entity)
          unless SIMULATION
            Relationship.relate_and_save(place_entity, "place locates / located holder", holder_entity)
          end
        end
      end
    end
  puts "Finished place locates / located holder"

  default = Collection.where(:name => 'default').first
  person = Kind.where(:name => 'Person').first
  medium = Kind.where(:name => 'Medium').first

  relationship =
    medium.entities.each do |medium_entity|
      person.entities.where(:name => medium_entity.dataset['medium_was_created_by_person']).each do |person_entity|
        puts "SUCCESS"
        unless Relationship.related?(medium_entity, "medium was created by person", person_entity)
          unless SIMULATION
            Relationship.relate_and_save(medium_entity, "medium was created by person", person_entity)
          end
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
          unless SIMULATION
            Relationship.relate_and_save(artefact_entity, "artefact was documented by person", person_entity)
          end
        end
      end
    end
  puts "Finished artefact_was_documented_by_person"


Entity.media.all.each do |entity|
  value = entity.dataset['date_time_created']
  entity.outgoing_relationships.where(relation_name: 'medium was created by person').each do |dr|
    datings = dr.relationship.datings

    # add new ones after checking the condition if there is relation dating yet
    if datings.where(label: 'Creation Date of Medium').count == 0
      if value.present? # this checks for the empty string, only white-space, nil, 0 and so on
        dr.relationship.datings << RelationshipDating.new(label: 'Creation Date of Medium', dating_string: value)
      end
      puts value
      # das folgende ist evtl. nicht notwendig, weil oben schon abgefragt wird, ob vorhanden und wenn nicht, dann erstellen
      #  remove all datings but the first
      if datings.where(label: 'Creation Date of Medium').count > 1
        to_be_removed = datings.where(label: 'Creation Date of Medium').to_a[1..-1] # array indices start at 0 and go to -1
        to_be_removed.each{|d| d.destroy}
      end
    end
  end
  puts 'done'
end
puts 'finished relation dating medium was created by person'

Entity.media.all.each do |entity|
  value = entity.dataset['date_time_created']
  entity.outgoing_relationships.where(relation_name: 'medium depicts artefact').each do |dr|
    datings = dr.relationship.datings

    # add new ones after checking the condition if there is relation dating yet
    if datings.where(label: 'Creation Date of Medium').count == 0
      if value.present? # this checks for the empty string, only white-space, nil, 0 and so on
        dr.relationship.datings << RelationshipDating.new(label: 'Creation Date of Medium', dating_string: value)
      end
      puts value
      # das folgende ist evtl. nicht notwendig, weil oben schon abgefragt wird, ob vorhanden und wenn nicht, dann erstellen
      #  remove all datings but the first
      if datings.where(label: 'Creation Date of Medium').count > 1
        to_be_removed = datings.where(label: 'Creation Date of Medium').to_a[1..-1] # array indices start at 0 and go to -1
        to_be_removed.each{|d| d.destroy}
      end
    end
  end
  puts 'done'
end
puts 'finished relation dating medium depicts artefact'

Entity.media.all.each do |entity|
  value = entity.dataset['date_time_created']
  entity.outgoing_relationships.where(relation_name: 'medium was created from collection').each do |dr|
    datings = dr.relationship.datings

    # add new ones after checking the condition if there is relation dating yet
    if datings.where(label: 'Creation Date of Medium').count == 0
      if value.present? # this checks for the empty string, only white-space, nil, 0 and so on
        dr.relationship.datings << RelationshipDating.new(label: 'Creation Date of Medium', dating_string: value)
      end
      puts value
      # das folgende ist evtl. nicht notwendig, weil oben schon abgefragt wird, ob vorhanden und wenn nicht, dann erstellen
      #  remove all datings but the first
      if datings.where(label: 'Creation Date of Medium').count > 1
        to_be_removed = datings.where(label: 'Creation Date of Medium').to_a[1..-1] # array indices start at 0 and go to -1
        to_be_removed.each{|d| d.destroy}
      end
    end
  end
  puts 'done'
end
puts 'finished relation dating medium was created from collection'

Entity.media.all.each do |entity|
  value = entity.dataset['date_time_created']
  entity.outgoing_relationships.where(relation_name: 'medium was created at place').each do |dr|
    datings = dr.relationship.datings

    # add new ones after checking the condition if there is relation dating yet
    if datings.where(label: 'Creation Date of Medium').count == 0
      if value.present? # this checks for the empty string, only white-space, nil, 0 and so on
        dr.relationship.datings << RelationshipDating.new(label: 'Creation Date of Medium', dating_string: value)
      end

      # das folgende ist evtl. nicht notwendig, weil oben schon abgefragt wird, ob vorhanden und wenn nicht, dann erstellen
      #  remove all datings but the first
      if datings.where(label: 'Creation Date of Medium').count > 1
        to_be_removed = datings.where(label: 'Creation Date of Medium').to_a[1..-1] # array indices start at 0 and go to -1
        to_be_removed.each{|d| d.destroy}
      end
    end
  end
  puts 'done'
end
puts 'finished relation dating medium was created at place'

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
