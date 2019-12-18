#!/usr/bin/env ruby

KOR_ROOT='/home/kor/kor'

require 'pry'
require "#{KOR_ROOT}/config/environment"

def pretty(relationship)
  r = relationship
  "#{r.id}: #{r.from.name} - #{r.relation.name} / #{r.relation.reverse_name} -> #{r.to.name}"
end

counts = Relationship.group(:from_id, :relation_id, :to_id).count
counts.each do |combination, count|
  if count > 1
    p "-- #{combination.inspect}: #{count}"

    relationships = Relationship.where(
      from_id: combination[0],
      relation_id: combination[1],
      to_id: combination[2]
    )

    relationships.each do |r|
      puts pretty(r)
    end

    properties = relationships.map{|r| r.properties}.uniq
    if properties.size > 1
      puts "properties are not the same for all relationships:"
      p properties
      next
    end

    datings = relationships.map{|r| r.datings.map{|d| [d.label, d.dating_string]}}.uniq
    if datings.size > 1
      puts "datings are not the same for all relationships"
      p datings
      next
    end

    relationships[1..-1].each do |r|
      puts "deleting #{r.id}"
    end
  end
end
