
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

    def change
      if self.grow?
        change = self.grow
      elsif self.shrink?
        change = self.shrink
      else
        change = capacity
      end
      change
    end
  end
end
