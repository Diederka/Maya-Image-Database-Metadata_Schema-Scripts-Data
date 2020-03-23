#!/usr/bin/env ruby

require 'pry'
require 'dotenv'
Dotenv.load

require "#{ENV['KOR_ROOT']}/config/environment"

def exif_for(path)
  output = `#{ENV['EXIFTOOL']} -j #{path}`
  JSON.parse(output)[0]
end

scope = Entity.media.includes(:medium)

pb = Kor.progress_bar 'parsing exif', scope.count

scope.find_each do |entity|
  path = entity.medium.path(:original)
  data = exif_for(path)
  File.open "exif/#{entity.id}.json", 'w' do |f|
    f.write(JSON.pretty_generate data)
  end
  pb.increment
end
