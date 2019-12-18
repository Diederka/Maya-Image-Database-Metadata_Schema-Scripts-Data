#!/usr/bin/env ruby

KOR_ROOT='/home/kor/kor'
SIMULATION=true

puts "SIMULATION MODE" if SIMULATION

require 'pry'
require "#{KOR_ROOT}/config/environment"

def validate(relationship, normal, reversal)
  if [relationship, normal, reversal].any?{|e| e.nil?}
    ids = [relationship.try(:id), normal.try(:id), reversal.try(:id)]
    puts "incomplete data for validation: #{ids.inspect}"
  end

  if relationship.name != normal.relation_name ||
     relationship.reverse_name != reversal.relation_name
     relationship.id != normal.relationship_id ||
     relationship.id != reversal.relationship_id
     
     binding.pry
     unless SIMULATION
       relationship.ensure_directed
       relationship.save!
     end
  end
end

Relationship.find_each do |r|
  validate(r, r.normal, r.reversal)
end

DirectedRelationship.find_each do |dr|
  if dr.is_reversal?
    validate(dr.relationship, dr.relationship.normal, dr)
  else
    validate(dr.relationship, dr, dr.relationship.reversal)
  end
end