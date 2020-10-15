KOR_ROOT = ENV['KOR_ROOT']

# gem 'pry', '=0.11.3'
# gem 'coderay', '=1.1.2'
# require 'pry'

require "#{KOR_ROOT}/config/environment"

class IaeManifestGenerator
  def initialize(entity)
    @json = Jbuilder.new
    @entity = entity

    dimensions = `identify -format '%wx%h' #{@entity.medium.path(:normal)}`
    @width, @height = dimensions.split('x').map{|v| v.to_i}
    dimensions = `identify -format '%wx%h' #{@entity.medium.path(:thumbnail)}`
    @thumb_width, @thumb_height = dimensions.split('x').map{|v| v.to_i}
  end

  attr_reader :json

  def run
    json.set! '@context', 'http://iiif.io/api/presentation/2/context.json'
    json.set! '@id', app.iiif_manifest_url(@entity)
    json.set! '@type', 'sc:Manifest'

    json.label "#{I18n.t 'activerecord.models.entity', count: 1} #{@entity.id}"
    json.description @entity.dataset['image_description']
    json.logo "https://classicmayan.kor.de.dariah.eu/dav-static/pics/twkm-logo.png"
    json.license "#{@entity.dataset['license']}, #{@entity.dataset['rights_holder']}"
    json.attribution "All images are provided by the Maya Image Archive"
    json.seeAlso app.root_url

    json.metadata metadata do |field|
      json.label field[:label]
      json.value field[:value]
    end

    json.sequences [0] do
      json.set! '@id', app.iiif_sequence_url(@entity)
      json.set! '@type', 'sc:Sequence'
      json.label 'the only sequence'

      json.canvases [0] do
        json.set! '@id', app.iiif_canvas_url(@entity)
        json.set! '@type', 'sc:Canvas'
        json.label 'the only image'

        json.width @width
        json.height @height

        json.thumbnail do
          json.set! '@id', app.root_url + @entity.medium.url(:thumbnail).gsub(/\?.*$/, '')
          json.width @thumb_width
          json.height @thumb_height
          json.format 'image/jpeg'
        end

        json.images [0] do
          json.set! '@id', app.iiif_image_url(@entity, format: :json)
          json.set! '@type', 'oa:Annotation'

          json.motivation 'sc:painting'
          json.on app.iiif_canvas_url(@entity, format: :json)

          json.resource do
            json.set! '@id', app.root_url + @entity.medium.url(:normal).gsub(/\?.*$/, '')
            json.set! '@type', 'dctypes:Image'
            json.format 'image/jpeg'
            json.width @width
            json.height @height
          end
        end
      end
    end
    
    json.attributes!
  end

  def metadata
    return [
      {
        label: 'filename',
        value: @entity.medium.original.original_filename
      },
      {
        label: 'Link to DB entry',
        value: app.web_url(anchor: app.entity_path(@entity))
      }
    ]
  end

  # so we can use helpers
  def app
    @app ||= begin
      result = ActionDispatch::Integration::Session.new(Rails.application)

      def result.default_url_options
        return {
          protocol: 'https',
          host: 'classicmayan.kor.de.dariah.eu'
        }
      end

      result
    end
  end
end

BASE_DIR="#{Rails.root}/public/mirador/manifests"
system "mkdir -p #{BASE_DIR}"
system "rm -f #{BASE_DIR}/*"

progress = Kor.progress_bar('generating manifests', Entity.media.count)

Entity.media.includes(:medium).find_each do |entity|
  data = IaeManifestGenerator.new(entity).run
  File.open "#{BASE_DIR}/#{entity.id}.json", 'w' do |f|
    f.write JSON.pretty_generate(data)
  end
  # puts JSON.pretty_generate(data)
  # exit
  progress.increment
end
