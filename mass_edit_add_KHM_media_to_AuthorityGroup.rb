# adding many specified media to an authority group 
# 2019

# load debugger, .env and KOR
require 'pry'
require 'dotenv'
Dotenv.load
require "#{ENV['KOR_ROOT']}/config/environment"
# ---

# To add  many media entities to one global group first I have to grab a hold of them, 
# potentially filter them and then add them to the group like this:

# to find all medium entities
entities = Entity.media

# to filter them by some filename pattern

entities = entities.to_a.select do |entity|
  entity.medium.original.original_filename.match(/^KHM/)
end

# get the authority group

authority_group = AuthorityGroup.find_by!(name: 'Karl Herbert Mayer Image Archive')

# add the entities

authority_group.add_entities(entities)
