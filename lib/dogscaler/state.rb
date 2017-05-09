module Dogscaler
  class State
    include Logging
  	def initialize
  	  @state = self.load
      @config = '/tmp/dogscaler.yaml'
  	end
  	def load
      begin
    	  YAML.load_file(config)
      rescue
        {}
      end
  	end
  	def get(asg)
  	  @state[asg] || Time.parse("2017-01-31 12:00:00")
  	end
  	def update(asg)
      t = Time.now
      logger.debug "Updating the timestamp for #{asg} to #{t}"
  	  @state[asg] = t
  	end
    def save!
      logger.debug "Saving state to #{@config}"
      File.open( @config, 'w' ) do |out|
        YAML.dump( @state, out )
      end
    end
  end
end
