
module Dogscaler
  class Instance
    include Virtus.model
    include Logging
    attribute :name, String
    attribute :cooldown_period, Integer
    attribute :queries, Array, :default => []
    attribute :parsed_queries, Array
    attribute :grow_by, Integer, :default => 1
    attribute :shrink_by, Integer, :default => 1
    attribute :asg_tag_filters, Hash
    attribute :autoscale_group, String
    attribute :capacity, Integer

    def initialize
      @checks = []
    end
    def cooldown
      self.cooldown_period || 60
    end

    def asg
      @asg ||= aws.get_asg(self.autoscale_group, self.asg_tag_filters)
    end

    def aws
      @aws ||= Dogscaler::AwsClient.new
    end

    def checks
      @checks
    end

    def max_instances
      asg.max_size
    end

    def min_instances
      asg.min_size
    end

    def autoscalegroupname
      asg.auto_scaling_group_name
    end

    def preflight_checks(state)
      # Quick fail filters
      # Don't do anything if we're already at the capactiy we think we should be
      if self.change == self.capacity
        logger.debug "Instance count: #{self.change} matches capacity: #{self.capacity}"
        return false
      end
      # Don't do anything if we have scaled recently
      if Time.now - state.get(self.autoscalegroupname) < self.cooldown
        logger.debug "We've scaled too soon, cooling down"
        return false
      end
      # Don't do anything if the new value is lower than the minimium
      if self.change < self.min_instances
        logger.debug "New size: #{self.change} smaller than min count: #{self.min_instances}"
        return false
      end
      # Don't do anything if the new value is higher than the maximum
      if self.change > self.max_instances
        logger.debug "New size: #{self.change} larger than max count: #{self.max_instances}"
        if self.capacity == self.max_instances
          logger.debug "Already at max, doing nothing"
          return false
        else
          logger.debug "Updating to the max: #{self.max_instances}"
          self.change = self.max_instances
          return true
        end
      end
      true
    end

    def capacity
      asg.desired_capacity
    end

    def process_checks
      dd_client = Dogscaler::Datadog.new(Settings.datadog)
      self.queries.each do |i|
        check = Dogscaler::Check.new()
        check.attributes = i.symbolize_keys
        check.points = dd_client.process(i['query'])
        check.reduce!
        @checks << check
      end
    end

    def grow?
      self.checks.any? {|c| c.status > 0 }
    end

    def shrink?
      self.checks.any? {|c| c.status < 0 }
    end

    def shrink
      capacity + -shrink_by.to_i.abs
    end

    def grow
      capacity + grow_by.to_i.abs
    end

    def update_capacity(options)
      aws.set_capacity(self, options)
    end

    def change=(value)
      @change = value
    end

    def process_change
      if self.grow?
        change = self.grow
      elsif self.shrink?
        change = self.shrink
      else
        change = capacity
      end
      change
    end

    def change
      @change || process_change
    end

  end
end
