# import scripts for data ingest via database backend
# Authors: Maximilian Brodhun, Katja Diederichs and Moritz Schepp, 2018 - 2021

# new: 08.2019: culture and culture_in_aat get static values 

# environment vars

# ConedaKOR app dir
# KOR_ROOT

# simulation mode (default: false)
# SIMULATION

# import entities (default: false)
# DO_ENTITIES


# loading the rails environment
require "#{ENV['KOR_ROOT']}/config/environment"

# load debugger, fail gracefully
begin
  require 'pry'
rescue LoadError => e
end

# load additional libs and gems
require 'json'


class MayaImporter
  def initialize(opts)
    @opts = opts.reverse_merge(
      simulation: true,
      do_entities: false,
      csv_file: nil,
      images_dir: nil
    )

    @started_at = Time.now
    sleep 2

    @errors = []
  end

  def run
    ActiveJob::Base.queue_adapter = :inline
    ActiveJob::Base.logger.level = :debug
    ActiveRecord::Base.logger.level = :info

    puts "SIMULATION MODE" if @opts[:simulation]

    ActiveRecord::Base.transaction do
      if @opts[:do_entities]
        media
        artefacts
        collections
        people
        places
        provenances
        holders
      end

      relationships

      # add a dummy error so that the import fails
      # @errors << "dummy error"

      if @errors.any?
        puts @errors

        rollback
      end
    end

    if @errors.empty?
      puts "no errors reported, saving changes, ALL DONE"
    end
  end

  def media
    kind = Kind.find_by!(name: 'medium')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      image_path = image_path_for(record['Image Number'])

      unless image_path
        msg = "medium could not be created, file not found"
        error "#{msg}: #{record['Image Number']} (line #{i + 2})"
        next
      end
      
      collection = Collection.find_by! name: record['Access Managing Collection']

      dimensions = dimensions_for(image_path)
      dimensions = (dimensions ? dimensions[1].to_s : '')

      record['Date'] = 'undated' if record['Date'].match?(/9999/)

      dataset = {
        'image_no' => record['Image Number'],
        'image_dimensions' => dimensions,

        'image_description' => record['Image Description'],
        'folder_no' => record['Folder Number'],
        'license' => record['License'],
        'cc_license_uri' => record['License URI'],
        'creator' => record['Creator of Image'],
        'date_time_created' => record['Date'],
        'file_name' => record['Image Number'],

        'contributor' => "Project Text Database and Dictionary of Classic Mayan",
        'rights_holder' => record['Creator of Image'],
        'publisher' => "Maya Image Archive",
        'digitized_by' => record['Digitized by'],

        'source_x_dimension_unit' => "mm",
        'source_y_dimension_unit' => "mm",

        'medium_depicts_artefact' => record['Artefact Name'],
        'medium_was_created_by_person' => record['Creator of Image'],
        'medium_was_created_from_collection' => record['Collection Name'],
        'medium_was_created_at_place' => record['Place Name']
      }.select{|k, v| v.present?}

      entity = kind.entities.new(
        medium: (image_path ? Medium.new(document: File.open(image_path)) : nil),
        collection: collection,
        dataset: dataset,
        distinct_name: record['Image Number'],
        comment: record['Comment']
      )

      # if record['Date'] != 'undated'
      #   entity.datings << EntityDating.new(
      #     label: 'Year',
      #     dating_string: record['Date']
      #   )
      # end

      if entity.valid?
        entity.save unless @opts[:simulation]

        # We add the entity to the global group making sure the name is unique
        if name = record['Global Group']
          groups = AuthorityGroup.where(name: name)
          if groups.count == 0
            group = AuthorityGroup.create! name: name
            group.add_entities entity
          elsif groups.count == 1
            group = groups.first
            group.add_entities entity
          else
            error "there is more than one global group '#{name}' #{i + 2}"
          end
        end
      else
        msg = "medium could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: media (#{items.size} lines found in CSV file)"
  end

  def artefacts
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'artefact')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      dataset = {
        'artefact_type' => record['Artefact Type'],
        'artefact_type_in_twkm_database' => record['Artefact Type in TWKM Database'],
        'artefact_in_twkm_database' => record['Artefact in TWKM Database'],
        'catalog_no' => record['Catalogue Number'],
        'artefact_publication' => record['Artefact Publication'],
        'artefact_publication_zotero' => record['Artefact Publication Zotero'],
        'inventory_no' => record['Inventory Number'],
        'artefact_is_depicted_by_medium' => record['Image Number'],
        'artefact_was_located_in_place' => record['Place Name'],
        'artefact_originates_from_provenance' => record['Provenance Name'],
        'artefact_was_documented_by_person' => record['Creator of Image'],
        'artefact_was_held_by_collection' => record['Collection Name'],
        'culture' => "Maya",
        'culture_in_aat' => "300017826"
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Artefact Name']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else
        msg = "artefact could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: artefacts (#{items.size} lines found in CSV file)"
  end

  def collections
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'collection')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      next unless record['Collection Name']

      dataset = {
        'collection_was_held_by_holder' => record['Holder Name'],
        'collection_held_artefact' => record['Artefact Name'],
        'collection_was_located_in_place' => record['Place Name'],
        'collection_from_where_medium_was_created' => record['Image Number']
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Collection Name']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else
        msg = "collection could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: collections (#{items.size} lines found in CSV file)"
  end

  def people
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'person')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      dataset = {
        'person_created_medium' => record['Image Number'],
        'person_documented_artefact' => record['Artefact Name'],
        'person_visited_place' => record['Place Name']
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Creator of Image']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else

        msg = "person could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: people (#{items.size} lines found in CSV file)"
  end

  def places
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'place')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      dataset = {
       'place_in_twkm_database' => record['Place in TWKM Database'],
       'place_located_holder' => record['Holder Name'],
       'place_located_artefact' => record['Artefact Name'],
       'place_was_visited_by_person' => record['Creator of Image'],
       'place_located_collection' => record['Collection Name'],
       'place_where_medium_was_created' => record['Image Number']
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Place Name']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else
        msg = "place could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: places (#{items.size} lines found in CSV file)"
  end

  def provenances
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'provenance')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      dataset = {
        'provenance_in_twkm_website' => record['Provenance in TWKM Website'],
        'provenance_in_twkm_database' => record['Provenance in TWKM Database'],
        'provenance_is_origin_of_artefact' => record['Artefact Name']
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Provenance Name'],
        distinct_name: record['Distinct Provenance Name']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else
        msg = "provenance could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: provenances (#{items.size} lines found in CSV file)"
  end

  def holders
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    kind = Kind.find_by!(name: 'holder')

    items = read_csv(@opts[:csv_file])
    items.each_with_index do |record, i|
      next unless record['Holder Name']

      dataset = {
        'holder_in_twkm_website' => record['Holder in TWKM Website'],
        'holder_held_collection' => record['Collection Name'],
        'holder_was_located_in_place' => record['Place Name']
      }.select{|k, v| v.present?}

      attrs = {
        kind_id: kind.id,
        name: record['Holder Name']
      }
      entity = kind.entities.find_or_initialize_by attrs do |entity|
        entity.collection_id = guest_collection.id
        entity.dataset = dataset
      end

      if entity.valid?
        entity.save unless @opts[:simulation]
      else
        msg = "holder could not be created from CSV line #{i + 2}"
        error "#{msg}: #{entity.errors.full_messages}"
      end
    end

    puts "DONE: holders (#{items.size} lines found in CSV file)"
  end

  def url_for(entity)
    id = (entity.is_a?(Entity) ? entity.id : entity)
    "#{Kor.root_url}#/enities/#{id}"
  end

  def add_relationship(from, relation_name, to)
    return unless to

    unless Relationship.related?(from, relation_name, to)
      relationship = Relationship.relate(from, relation_name, to)

      if relationship.valid?
        relationship.save unless @opts[:simulation]
      else
        msg = "relationship '#{url_for(from)} - #{relation_name} - #{url_for(to)}'"
        error "#{msg} could not be created: #{relationship.errors.full_messages}"
      end
    end
  end

  def add_relationship_dating(relationship, attrs)
    return unless attrs[:dating_string].present?

    props = relationship.properties.
      select{|p| !p.match?(/^#{attrs[:label]}:/)}
    props << "#{attrs[:label]}: #{attrs[:dating_string]}"

    relationship.update_column :properties, props
  end

  # returns true if one of the records has been modified during this import run
  def recent?(records)
    records.compact.any? do |record|
      record.created_at >= @started_at ||
      record.updated_at >= @started_at
    end
  end

  def relationships
    guest_collection = Collection.find_by!(name: 'Guest Collection')
    places = Kind.find_by! name: 'Place'
    artefacts = Kind.find_by! name: 'Artefact'
    holders = Kind.find_by! name: 'Holder'
    provenances = Kind.find_by! name: 'Provenance'
    collection_kind = Kind.find_by! name: 'Collection'
    people = Kind.find_by! name: 'Person'
    media = Kind.find_by! name: 'medium'

    relation_name = "artefact is / was located in place"
    artefacts.entities.each do |artefact|
      place = places.entities.find_by name: artefact.dataset['artefact_was_located_in_place']
      next unless recent?([artefact, place])

      add_relationship(artefact, relation_name, place)
    end
    puts "DONE: #{relation_name}"

    relation_name = "place locates / located holder"
    places.entities.each do |place|
      holder = holders.entities.find_by name: place.dataset['place_located_holder']
      next unless recent?([place, holder])

      add_relationship(place, relation_name, holder)
    end
    puts "DONE: #{relation_name}"

    relation_name = "artefact originates from provenance"
    artefacts.entities.each do |artefact|
      provenance = provenances.entities.find_by name: artefact.dataset['artefact_originates_from_provenance']
      next unless recent?([artefact, provenance])

      add_relationship(artefact, relation_name, provenance)
    end
    puts "DONE: #{relation_name}"

    relation_name = "collection holds / held artefact"
    collection_kind.entities.each do |collection|
      artefact = artefacts.entities.find_by name: collection.dataset['collection_held_artefact']
      next unless recent?([collection, artefact])

      add_relationship(collection, relation_name, artefact)
    end
    puts "DONE: #{relation_name}"

    relation_name = "medium was created at place"
    media.entities.each do |medium|
      place = places.entities.find_by name: medium.dataset['medium_was_created_at_place']
      next unless recent?([medium, place])

      add_relationship(medium, relation_name, place)
    end
    puts "DONE: #{relation_name}"

    relation_name = "place locates / located collection"
    places.entities.each do |place|
      collection = collection_kind.entities.find_by name: place.dataset['place_located_collection']
      next unless recent?([place, collection])

      add_relationship(place, relation_name, collection)
    end
    puts "DONE: #{relation_name}"

    relation_name = "medium was created from collection"
    media.entities.each do |medium|
      collection = collection_kind.entities.find_by name: medium.dataset['medium_was_created_from_collection']
      next unless recent?([medium, collection])

      add_relationship(medium, relation_name, collection)
    end
    puts "DONE: #{relation_name}"

    relation_name = "medium depicts artefact"
    media.entities.each do |medium|
      artefact = artefacts.entities.find_by name: medium.dataset['medium_depicts_artefact']
      next unless recent?([medium, artefact])

      add_relationship(medium, relation_name, artefact)
    end
    puts "DONE: #{relation_name}"

    relation_name = "collection is / was held by holder"
    collection_kind.entities.each do |collection|
      holder = holders.entities.find_by name: collection.dataset['collection_was_held_by_holder']
      next unless recent?([collection, holder])

      add_relationship(collection, relation_name, holder)
    end
    puts "DONE: #{relation_name}"

    relation_name = "place was visited by person"
    places.entities.each do |place|
      person = people.entities.find_by name: place.dataset['place_was_visited_by_person']
      next unless recent?([place, person])

      add_relationship(place, relation_name, person)
    end
    puts "DONE: #{relation_name}"

    relation_name = "place locates / located holder"
    places.entities.each do |place|
      holder = holders.entities.find_by name: place.dataset['place_located_holder']
      next unless recent?([place, holder])

      add_relationship(place, relation_name, holder)
    end
    puts "DONE: #{relation_name}"

    relation_name = "medium was created by person"
    media.entities.each do |medium|
      person = people.entities.find_by name: medium.dataset['medium_was_created_by_person']
      next unless recent?([medium, person])

      add_relationship(medium, relation_name, person)
    end
    puts "DONE: #{relation_name}"

    relation_name = "artefact was documented by person"
    artefacts.entities.each do |artefact|
      person = people.entities.find_by name: artefact.dataset['artefact_was_documented_by_person']
      next unless recent?([artefact, person])

      add_relationship(artefact, relation_name, person)
    end
    puts "DONE: #{relation_name}"

    task = "relation dating medium was created by person"
    media.entities.each do |medium|
      value = medium.dataset['date_time_created']
      # next if value && value.match?(/undated/)

      medium.outgoing_relationships.where(relation_name: 'medium was created by person').each do |dr|
        next unless recent?([medium, dr.from, dr.to])
        
        datings = dr.relationship.datings

        add_relationship_dating(dr.relationship,
          label: 'Creation Date of Medium',
          dating_string: value
        )
      end
    end
    puts "DONE: #{task}"

    task = 'relation dating medium depicts artefact'
    media.entities.each do |medium|
      value = medium.dataset['date_time_created']
      # next if value && value.match?(/undated/)

      medium.outgoing_relationships.where(relation_name: 'medium depicts artefact').each do |dr|
        next unless recent?([medium, dr.from, dr.to])

        datings = dr.relationship.datings
        add_relationship_dating(dr.relationship,
          label: 'Creation Date of Medium',
          dating_string: value
        )
      end
    end
    puts "DONE: #{task}"

    task = 'relation dating medium was created from collection'
    media.entities.each do |medium|
      value = medium.dataset['date_time_created']
      # next if value && value.match?(/undated/)

      medium.outgoing_relationships.where(relation_name: 'medium was created from collection').each do |dr|
        next unless recent?([medium, dr.from, dr.to])

        datings = dr.relationship.datings
        add_relationship_dating(dr.relationship,
          label: 'Creation Date of Medium',
          dating_string: value
        )
      end
    end
    puts "DONE: #{task}"

    task = 'relation relation dating medium was created at place'
    media.entities.each do |medium|
      value = medium.dataset['date_time_created']
      # next if value && value.match?(/undated/)
      
      medium.outgoing_relationships.where(relation_name: 'medium was created at place').each do |dr|
        next unless recent?([medium, dr.from, dr.to])

        datings = dr.relationship.datings
        add_relationship_dating(dr.relationship,
          label: 'Creation Date of Medium',
          dating_string: value
        )
      end
    end
    puts "DONE: #{task}"

    # just needed once, deactivating:
    # task = 'convert relationship datings to properties'
    # Relationship.includes(:datings).all.each do |r|
    #   next if r.datings.empty?

    #   props = r.datings.map{|d| "#{d.label}: #{d.dating_string}"}
    #   puts "#{r.from_id} -> #{r.to_id}: #{props.inspect}"
    #   unless r.update_attributes properties: (r.properties + props).uniq
    #     @errors <<
    #       "could not convert datings on relationship #{r.id} to " +
    #       "properties: #{r.errors.full_messages.join(', ')}"
    #   end
    #   r.datings.destroy_all
    # end
    # puts "DONE: #{task}"

    # just needed once, deactivating:
    # ask = 'drop dating "Year" from media entities'
    # datings = EntityDating.
    #   joins(:owner).
    #   where('entities.kind_id = ?', Kind.medium_kind).
    #   where(label: 'Year').
    #   destroy_all
    # puts "DONE: #{task}"
  end


  protected

    def rollback
      puts "DATA ERRORS OCURRED, see above for details, rolling back changes"
      raise ActiveRecord::Rollback
    end

    # read csv file ensuring an array of hashes (even if empty or if the file
    # doesn't exist). Record keys are taken from the first line (headers).
    # @param path [String] the path to the csv file
    # @return [Array<String>] an array with each line of data from the csv file
    def read_csv(path)
      unless File.exists?(path)
        puts "file #{path} doesn't exist"
        return []
      end

      lines = File.read(path).
        split(/[\r\n]+/).
        reject{|l| l.match? /^;*$/}
      headers = lines[0].split(';').map{|e| e.strip.gsub(/ {2,}/, ' ')}
      lines[1..-1].map do |line|
        fields = line.split(';').map{|e| e.strip.gsub(/ {2,}/, ' ')}
        headers.
          zip(fields).
          to_h.
          select{|k, v| v.present?}
      end
    end

    def error(message)
      @errors << message
    end

    # get image dimensions
    # @param path [String] the path to the file
    # @return [Integer, Integer] the image dimensions
    def dimensions_for(path)
      return nil if path.nil?
      return nil unless File.file?(path)

      r, w = IO.pipe
      pid = Process.spawn('identify', '-format', "%wx%h", path, out: w, err: '/dev/null')
      w.close
      pid, status = Process.wait2(pid)

      status == 0 ? r.read.split('x').map{|e| e.to_i} : nil
    end

    def image_path_for(image_number)
      image_path = "#{@opts[:images_dir]}/#{image_number}.jpg"
      
      if !File.exists?(image_path)
        case_image_path = cs_image(image_path)

        if !case_image_path || !File.exists?(case_image_path)
          return nil
        end

        return case_image_path
      end

      image_path
    end

    # returns the case sensitive version for a case insensitive image path if the
    # path can be found in the file system
    # @param path [String] the case insensitive path to be verified
    # @return [String] the case sensitive path found if it exists
    # @return [nil] if the file couldn't be found
    def cs_image(path)
      Dir["#{@opts[:images_dir]}/*"].find do |candidate|
        if candidate.downcase == path.downcase
          return candidate
        end
      end

      nil
    end

end

class DataError < StandardError

end

import = MayaImporter.new(
  simulation: ENV['SIMULATION'] == 'true',
  do_entities: ENV['DO_ENTITIES'] == 'true',
  csv_file: ENV['CSV_FILE'],
  images_dir: ENV['IMAGES_DIR']
)

import.run

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
