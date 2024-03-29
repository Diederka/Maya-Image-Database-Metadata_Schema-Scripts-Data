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

  if relationship.relation.name != normal.relation_name ||
     relationship.relation.reverse_name != reversal.relation_name
     relationship.id != normal.relationship_id ||
     relationship.id != reversal.relationship_id
     
     unless SIMULATION
       relationship.ensure_directed
       relationship.save!
     end
  end
end

Relationship.includes(:relation, :normal, :reversal).find_each do |r|
  validate(r, r.normal, r.reversal)
end

DirectedRelationship.includes(relationship: [:normal, :reversal]).find_each do |dr|
  if dr.is_reverse?
    validate(dr.relationship, dr.relationship.normal, dr)
  else
    validate(dr.relationship, dr, dr.relationship.reversal)
  end
end

DirectedRelationship.with_from.where('froms.id IS NULL').each do |dr|
  dr.relationship.destroy
end

DirectedRelationship.with_to.where('tos.id IS NULL').each do |dr|
  dr.relationship.destroy
end
