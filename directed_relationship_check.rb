#!/usr/bin/env ruby

KOR_ROOT='/home/kor/kor'
SIMULATION=true

puts "SIMULATION MODE" if SIMULATION

require 'pry'
require "#{KOR_ROOT}/config/environment"

def validate(relationship, normal, reverse)
  if [relationship, normal, reverse].any?{|e| e.nil?}
    ids = [relationship.try(:id), normal.try(:id), reverse.try(:id)]
    puts "incomplete data for validation: #{ids.inspect}"
  end

  if relationship.name != normal.relation_name ||
     relationship.reverse_name != reverse.relation_name
     relationship.id != normal.relationship_id ||
     relationship.id != reverse.relationship_id
     
     binding.pry
     unless SIMULATION
       relationship.ensure_directed
       relationship.save!
     end
  end
end
