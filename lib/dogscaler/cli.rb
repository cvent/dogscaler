require 'logger'
# Used for the symbolize_keys method
require 'facets'

module Dogscaler
  class Cli < Thor
    include Logging
    class_option :debug, :aliases => [ :d ],
      :type  => :boolean, :banner => "Enable debug mode", :default => false
    class_option :region, :aliases => [ :r ],
      :type => :string, :banner => "AWS Region", :default => 'us-west-2'
    class_option :verbose, :aliases => [ :v ],
      :type => :boolean, :banner => "Verbose Output", :default => false
    class_option :terse, :aliases => [ :t],
      :type => :boolean, :banner => "Terse Output", :default => false
    class_option :dryrun, :alias => [ :n ],
      :type  => :boolean, :banner => "Do a dry run", :default => false
    class_option :config,
      :type  => :string, :banner => "Path to configuration file"


    #logger.level = options[:debug] ? Logger::DEBUG : Logger::INFO
    desc "debug", "testing command, describes the query it ran and the results"
    def debug
      Settings.load!(File.expand_path(options[:config])) if options[:config]
      Settings.instances.each do |i|
        instance = Dogscaler::Instance.new
        instance.attributes = i.symbolize_keys
        dd_client = Dogscaler::Datadog.new(Settings.datadog)
        require 'pp'
        pp instance.query
        dd_client.process(instance)
      end
    end

    desc "config", "Generate a default configuration"
    def config
      Dogscaler::Config.new.generate
    end

    desc "apply", "Scale the environment based on a query"
    def apply
      Settings.load!(File.expand_path(options[:config])) if options[:config]
      aws = Dogscaler::AwsClient.new
      if options[:debug]
        self.class.logger.level = Logger::DEBUG
      elsif options[:terse]
        self.class.logger.level = Logger::ERROR
      elsif options[:verbose]
        self.class.logger.level = Logger::INFO
      else
        self.class.logger.level = Logger::WARN
      end


      Settings.instances.each do |i|
        instance = Dogscaler::Instance.new
        instance.attributes = i.symbolize_keys
        dd_client = Dogscaler::Datadog.new(Settings.datadog)
        dd_client.process(instance)
        asgs = aws.get_asg(instance.autoscale_group, instance.asg_tag_filters)
        asgs.each do |asg|
          instance.capacity = asg.desired_capacity
          instance.min_instances = asg.min_size
          instance.max_instances = asg.max_size
          instance.autoscale_group = asg.auto_scaling_group_name
          logger.debug "Instance: #{instance.autoscale_group}"
          logger.debug "min_instances: #{instance.min_instances}"
          logger.debug "max_instances: #{instance.max_instances}"
          logger.debug "desired_capacity: #{instance.capacity}"
          logger.debug "instance status: #{instance.status}"
          case instance.status
          when 'grow'
            if instance.capacity < instance.max_instances
              if instance.max_instances == 0
                logger.warn "Would have increased capacity of #{instance.autoscale_group} but current value is 0"
              else
                aws.set_capacity(instance, instance.grow_by, options)
              end
            else
              logger.warn "Would have increased capacity of #{instance.autoscale_group} but already at maximum."
              logger.warn "Current desired: #{instance.capacity}"
              logger.warn "Current max: #{instance.max_instances}"
            end
          when 'shrink'
            if instance.capacity > instance.min_instances
              aws.set_capacity(instance, instance.shrink_by, options)
            else
              logger.warn "Would have reduced capacity of #{instance.autoscale_group} but already at minimum."
              logger.warn "Current desired: #{instance.capacity}"
              logger.warn "Current min: #{instance.min_instances}"
            end
          when 'okay'
            logger.info "Capacity within expected parameters, no changes."
          end
        end
      end
    end
  end
end
