require 'dogapi'
module Dogscaler
  class Datadog
    include Logging
    def initialize(settings)
        @dog ||= Dogapi::Client.new(settings['api_key'], settings['application_key'])
    end

    def process(query, period=5)
      to = Time.now
      from = to - (period.to_i*60)
      res = @dog.get_points(query, from.strftime('%s'), to.strftime('%s'))
      if res[0] != '200'
        logger.error "Error code generated on query, please validate your api keys, and query"
        logger.error "query: #{instance.query}"
        logger.error "Result: #{res}"
        exit 1
      end
      if res[1]['series'].empty?
        logger.error "No results returned from query #{instance.query}"
        exit 1
      end
      points = unzip(res)

    end

    def unzip(raw)
      points = []
      raw[1]['series'][0]['pointlist'].each {|k,v| points << v.to_i }
      points
    end
  end
end

