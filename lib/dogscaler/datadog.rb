require 'dogapi'
require 'pp'
module Dogscaler
  class Datadog
    include Logging
    def initialize(settings)
        @dog = Dogapi::Client.new(settings['api_key'], settings['application_key'])
    end

    def process(instance, period=5)
      to = Time.now
      from = to - (period.to_i*60)
      res = @dog.get_points(instance.query, from.strftime('%s'), to.strftime('%s'))
      if res[0] != '200'
        logger.error "Error code generated on query, please validate your api keys, and query"
        logger.debug "query: #{instance.query}"
        logger.debug "Result: #{res}"
        exit 1
      end
      if res[1]['series'].empty?
        logger.error "No results returned from query #{instance.query}"
        exit 1
      end
      points = unzip(res)
      instance.points = points
      instance.reduce!
    end

    def unzip(raw)
      points = []
      raw[1]['series'][0]['pointlist'].each {|k,v| points << v.to_i }
      points
    end
  end
end

