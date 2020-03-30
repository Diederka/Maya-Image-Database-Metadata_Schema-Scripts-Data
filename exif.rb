#!/usr/bin/env ruby

require 'pry'
require 'dotenv'
Dotenv.load

require "#{ENV['KOR_ROOT']}/config/environment"

def exif_for(path)
  output = `#{ENV['EXIFTOOL']} -j #{path}`
  JSON.parse(output)[0]
end

def read_cache
  puts 'reading EXIF cache ...'
  results = {}
  Dir["#{ENV['EXIF_CACHE']}/*.json"].each do |f|
    id = f.split('/').last.split('.').first.to_i
    results[id] = JSON.load(File.read f)
  end
  results
end

def fill_cache
  scope = Entity.media.includes(:medium)
  pb = Kor.progress_bar 'parsing exif', scope.count
  scope.find_each do |entity|
    cache_file = "#{ENV['EXIF_CACHE']}/#{entity.id}.json"
    unless File.exists?(cache_file)
      path = entity.medium.path(:original)
      data = exif_for(path)
      File.open cache_file, 'w' do |f|
        f.write(JSON.pretty_generate data)
      end
    end
    pb.increment
  end
end

fill_cache
data = read_cache
# binding.pry

puts 'matching EXIF data to media ...'
Entity.media.includes(:medium).each do |entity|
  file_name = 
    entity.dataset['file_name'].presence ||
    entity.medium.image.original_filename
  exif = data[entity.id]

  # this holds the changes to be applied to this entity's dataset
  new_dataset = {}

  # do this for all images
  if exif # but only if we found any exif data
    mapping = {
      'ColorSpaceData' => 'color_space',
      'FileName' => 'file_name',
      'xResolution' => 'maximum_optical_resolution',
      'ImageWidth' => 'source_x_dimension_value',
      'ExifImageWidth' => 'source_x_dimension_value',
      'ImageHeight' => 'source_y_dimension_value',
      'ExifImageHeight' => 'source_y_dimension_value',
      'Make' => 'digital_camera_manufacturer',
      'Model' => 'digital_camera_model_name'
    }
    mapping.each do |from, to|
      if exif[from].present? && !entity.dataset[to].present? && !new_dataset[to].present?
        new_dataset[to] = exif[from]
      end
    end
  end

  # do this only for images starting with 'MET_', even if there was no exif data
  if file_name.match?(/^MET_/)
    mapping = {
      'rights_holder' => 'Public Domain',
      'publisher' => 'Metropolitan Museum of Art',
      'contributor' => 'Maya Image Archive'
    }
    mapping.each do |field, value|
      if !entity.dataset[field].present? && !new_dataset[to].present?
        new_dataset[field] = value
      end
    end
  end

  # do this only for images NOT starting with 'MET_', 'KHM_', 'NG_' or 'PAU_'
  if exif # but only if there is exif data
    if !file_name.match?(/^(MET|KHM|NG|PAU)_/)
      mapping = {
        'Copyright' => 'rights_holder',
        'CreationDate' => 'date_time_created'
      }
      mapping.each do |from, to|
        if exif[from].present? && !entity.dataset[to].present? && !new_dataset[to].present?
          new_dataset[to] = exif[from]
        end
      end
    end
  end

  unless new_dataset.empty?
    puts "entity #{entity.id}: applying new dataset values #{new_dataset.inspect}"
    # entity.dataset.merge!(new_dataset)
  end
end
