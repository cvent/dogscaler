require 'dogapi'
require 'pp'

module Dogscaler
  class Datadog
    def initialize(settings)
        @dog = Dogapi::Client.new(settings['api_key'], settings['application_key'])
    end

    def process(instance, period=5)
      to = Time.now
      from = to - (period.to_i*60)
      res = @dog.get_points(instance.query, from.strftime('%s'), to.strftime('%s'))
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

