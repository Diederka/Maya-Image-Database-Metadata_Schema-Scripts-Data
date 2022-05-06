#!/usr/bin/env ruby

require 'nokogiri'
require 'ruby-progressbar'
begin; require 'pry'; rescue LoadError => e; end

class CombineOaiXml
  def initialize(opts)
    @opts = opts
    @entities = {}
    @relationships = {}
  end

  def index_entities
    Dir[@opts[:dir] + '/entities/*.xml'].each do |f|
      doc = Nokogiri::XML(File.read f)
      doc.remove_namespaces!
      uuid = doc.xpath('//id').first.text.strip
      kind = doc.xpath('//type').first.text.strip
      @entities[kind] ||= []
      @entities[kind] << uuid
    end
  end

  def load_entity(uuid)
    file = @opts[:dir] + "/entities/#{uuid}.xml"
    doc = Nokogiri::XML(File.read file)
    doc.remove_namespaces!
    doc.root.delete 'xsi:schemaLocation'
    doc
  end

  def index_relationships
    Dir[@opts[:dir] + '/relationships/*.xml'].each do |f|
      doc = Nokogiri::XML(File.read f)
      doc.remove_namespaces!
      from = doc.xpath('//from').first.text.strip
      to = doc.xpath('//to').first.text.strip
      name = doc.xpath('//relation/@name').first.text.strip
      reverse_name = doc.xpath('//relation/@reverse-name').first.text.strip
      @relationships[from] ||= {}
      @relationships[from][name] ||= []
      @relationships[from][name] << to
      @relationships[to] ||= {}
      @relationships[from][reverse_name] ||= []
      @relationships[from][reverse_name] << from
    end
  end

  def run
    index_entities
    index_relationships

    combine
  end

  def combine
    out_free = Nokogiri::XML(
      '<entities></entities>'
    )
    count_free = 0
    out_nonfree = Nokogiri::XML(
      '<entities></entities>'
    )
    count_nonfree = 0

    @entities['Artefact'].each do |uuid|
      copy = load_entity(uuid).root
      free = true

      rels = @relationships[uuid] || []
      if rels.empty?
        puts "no relationships: #{uuid}"
      end

      rels.each do |name, uuids|
        copy << "<related relation=\"#{name}\"></related>"

        uuids.each do |uuid|
          entity = load_entity(uuid)
          if entity.root
            begin
              type = entity.root.xpath('//type').text
              license = entity.root.xpath("//field[@name='license']").text
              if type == 'Medium'
                if license == 'RS NKC 1.0' || license == 'RESERVED'
                  free = false
                end
              end

              copy.xpath("related[@relation='#{name}']").first << entity.root
            rescue StandardError => e
              binding.pry
            end
          else  
            puts "invalid entity: #{uuid}"
          end
        end
      end

      copy.delete 'xsi:schemaLocation'

      (free ? out_free : out_nonfree).root << copy
      (free ? count_free += 1 : count_nonfree += 1)
    end

    File.open @opts[:dir] + '/combined.free.xml', 'w' do |f|
      f.write out_free.to_xml
    end

    File.open @opts[:dir] + '/combined.nonfree.xml', 'w' do |f|
      f.write out_nonfree.to_xml
    end

    puts "free/nonfree: #{count_free}/#{count_nonfree}"
  end


  protected

    def new_progress(total, title = 'processing')
      ProgressBar.create(
        title: title,
        format: "%t: %B | %c/%C (%R/s) | %a |%e",
        total: total
      )
    end
end

CombineOaiXml.new(
  dir: './kor_xml'
).run
