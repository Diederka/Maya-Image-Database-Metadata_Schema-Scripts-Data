#!/usr/bin/env ruby

# This script allows the download of all entity types, relations, entities and
# relationships. The results are stored in a configurable target directory.
# After a full download has been completed (!), you can switch on incremental
# requests by setting the parameter "continue" to "true". This and other
# settings can be changed at the bottom of this script.

require 'pry'
require 'httpclient'
require 'nokogiri'
require 'ruby-progressbar'

module Kor
  class OaiPmhClient
    def initialize(options = {})
      @options = {
        delay: 0.2,
      }.merge options
      @options[:log_file] ||= "#{@options[:target_dir]}/oai_pmh.log"
      @request_duration = 0
      @request_count = 0
      @log_file = File.open(@options[:log_file], 'w+')
      @log_file.sync = true
    end

    def run
      if @options[:target_dir]
        FileUtils.mkdir_p @options[:target_dir]
      end

      fetch 'kinds', 'kind'
      fetch 'relations', 'relation'
      fetch 'entities', 'entity'
      fetch 'relationships', 'relationship'
    end

    def fetch(type, stype)
      resumptionToken = nil
      ids = []

      per_page = 50
      total = nil
      pg = nil

      loop do
        begin
          params = {'verb' => 'ListRecords'}
          params['from'] = from if @options[:continue]
          params['resumptionToken'] = resumptionToken if resumptionToken
          doc = oaipmh("/oai-pmh/#{type}.xml", params)

          if doc.xpath("//xmlns:error/@code").text == 'noRecordsMatch'
            break # nothing to do
          end

          rts = doc.xpath('//xmlns:resumptionToken')
          if rts.size > 0 && rts.text.size > 0
            # the response has a token and its not empty
            resumptionToken = rts.text

            unless pg
              total = rts.attr('completeListSize').value.to_i
              pg = new_progress(total / per_page, type)
            end
          else
            resumptionToken = nil
          end

          new_ids = doc.xpath("//kor:#{stype}/kor:id").map{ |i| i.text }
          if new_ids.size > 0
            ids += new_ids
          else
            log "an xml document has been received but no ids could be found: #{doc.to_xml}"
          end

          # deleted_ids = doc.xpath(" ")

          if @options[:target_dir]
            dir = "#{@options[:target_dir]}/#{type}"
            system "mkdir -p #{dir}"

            doc.xpath('//xmlns:record').each do |r|
              deleted = r.xpath('xmlns:header').first['status']
              id = r.xpath('xmlns:header/xmlns:identifier').text
              filename = "#{dir}/#{id}.xml"

              if deleted
                system "rm -f #{filename}"
              else
                record = r.xpath("*/kor:#{stype}").first
                File.open filename, 'w' do |f|
                  f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                  f.write record.to_xml
                end
              end
            end
          end

          break unless resumptionToken

          sleep @options[:delay]
          pg.increment
        rescue => e
          out = (doc ? doc.to_xml : 'NONE')
          log "#{e}\n#{e.backtrace.join("\n")}\ndoc:\n#{out}"
          sleep 1
          # binding.pry
        end
      end

      # binding.pry
      # puts "found #{ids.uniq.size} entities"
    end

    protected

      def from
        latest = Time.now
        Dir["#{@options[:target_dir]}/*/*.xml"].each do |f|
          latest = [File.stat(f).mtime, latest].max
        end
        latest -= 60 * 60 * 24
        latest.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      def new_progress(total, title = 'processing')
        ProgressBar.create(
          title: title,
          format: "%t: %B | page %c/%C (%R/s) | %a |%e",
          total: total
        )
      end

      def oaipmh(path, params)
        defaults = {'metadataPrefix' => 'kor', 'api_key' => @options[:api_key]}
        params = defaults.merge params
        response = request 'get', path, params
        if response.status < 200 || response.status > 499
          log "there was an error with the request [#{path} #{params.inspect}]: #{response.status}: #{response.body}"
          nil
        else
          parse(response.body)
        end
      end

      def parse(xml)
        doc = Nokogiri::XML(xml)
        doc.collect_namespaces.each do |k, v|
          unless doc.namespaces[k]
            doc.root.add_namespace k, v
          end
        end
        doc
      end

      def request(method, path, params)
        # puts "REQUEST: #{method} #{path} #{params.inspect}"
        delta = Time.now
        response = client.request method, "#{@options[:url]}#{path}", params
        delta = Time.now - delta
        @request_duration += delta
        @request_count += 1
        response
      end

      def average_request_duration
        return @request_duration / (@request_count)
      end

      def client
        @client ||= HTTPClient.new
      end

      def log(message)
        @log_file.puts "#{Time.now.strftime '%Y-%m-%d %H:%M:%S'} #{message}"
      end
  end
end

system 'mkdir kor_xml'

Kor::OaiPmhClient.new(
  url: 'https://classicmayan.kor.de.dariah.eu',
  api_key: 'MY API KEY',
  target_dir: './kor_xml',
  continue: false
).run
