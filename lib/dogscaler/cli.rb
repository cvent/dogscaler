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


    desc "debug", "testing command, describes the query it ran and the results"
    def debug
      Settings.load!(File.expand_path(options[:config])) if options[:config]
      Settings.instances.each do |i|
        instance = Dogscaler::Instance.new
        instance.attributes = i.symbolize_keys
        dd_client = Dogscaler::Datadog.new(Settings.datadog)
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

      if options[:debug]
        self.class.logger.level = Logger::DEBUG
      elsif options[:terse]
        self.class.logger.level = Logger::ERROR
      elsif options[:verbose]
        self.class.logger.level = Logger::INFO
      else
        self.class.logger.level = Logger::WARN
      end

      instances = []
      Settings.instances.each do |k,v|
        instance = Dogscaler::Instance.new
        instance.attributes = v.symbolize_keys
        instance.process_checks
        instances << instance
      end
      state = Dogscaler::State.new
      slack = Dogscaler::SlackClient.new(Settings.slack['api_token'], Settings.slack['channel'])
      instances.each do |instance|
        next if instance.change == instance.capacity
        next if Time.now - state.get(instance.autoscalegroupname) < instance.cooldown
        message = "Scaling #{instance.autoscalegroupname} from #{instance.capacity} to #{instance.change}"
        logger.info(message)
        if options[:dryrun]
          logger.info "Not updating due to dry run mode"
        else
          slack.send_message(message)
          state.update(instance.autoscalegroupname)
          instance.update_capacity(options)
        end
      end
      state.save!
    end
  end
end
