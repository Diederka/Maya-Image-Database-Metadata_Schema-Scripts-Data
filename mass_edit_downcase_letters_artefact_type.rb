# downcase of first letter in a word 
# katja Diederichs 2019 


KOR_ROOT="/home/kor/kor/"

# loading the rails environment
require "#{KOR_ROOT}/config/environment"

#find all kinds with the dataset field "artefact_type""
kind = Kind.where(:name => 'Artefact').first

#find all entities belongign to that kind
entity = kind.entities

kind.entities.each do |entity|
  # The if-clause makes it resilient against missing values for that field.
  if entity.dataset['artefact_type']
    #downcase the whole string because the rest of the word is always downcase
    entity.dataset['artefact_type'] = entity.dataset['artefact_type'].downcase
    entity.save
  end

  
  puts "downcasting is done"
end


# this was a trial of a code snippet to downcase only the first character. Is it possible? 
# artefactTypeString = entity.dataset['artefact_type'] 
#artefactTypeString = artefactTypeString[0].downcase

# or maybe just that?
# entity.dataset['artefact_type'] = entity.dataset['artefact_type'[0]].downcase
