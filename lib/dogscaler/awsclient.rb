require 'aws-sdk'

module Dogscaler
  class AwsClient
    NoResultsError = Class.new(StandardError)
    TooManyResultsError = Class.new(StandardError)
    NoAutoscaleNameFound = Class.new(StandardError)
    include Logging

    def initialize
      @credentials = Aws::SharedCredentials.new(profile_name: Settings.aws['profile'])
      @region = Settings.aws['region']
    end

    def asg_client
      @asg_client ||= Aws::AutoScaling::Client.new(credentials: @credentials, :region => @region)
    end

    def ec2_client
      @ec2_client ||= Aws::EC2::Client.new(credentials: @credentials, :region => @region)
    end

    def get_autoscale_groups
      next_token = nil
      autoscalegroups = []
      loop do
        body = {next_token: next_token}
        resp = asg_client.describe_auto_scaling_groups(body)
        asgs =  resp.auto_scaling_groups
        asgs.each do |instance|
          autoscalegroups << instance
        end
        next_token = resp.next_token
        break if next_token.nil?
      end
      return autoscalegroups
    end

    def autoscalegroups
      @@asgs ||= get_autoscale_groups
    end

    def get_asg(asg_name=nil, asg_tag_filters = {})
      raise NoAutoscaleNameFound if asg_name.nil? and asg_tag_filters.empty?

      if not asg_tag_filters.empty?
        asg_name = autoscalegroups.select do |group|
          validate_tags(group.tags, asg_tag_filters)
        end
      else
        asg_name = autoscalegroups.select do |group|
          group.auto_scaling_group_name == asg_name
        end
      end

      asg_name.select! do |group|
        group.desired_capacity > 0 and
        group.max_size > 0
      end

      raise TooManyResultsError if asg_name.count > 1
      raise NoResultsError if asg_name.empty?
      return asg_name.first
    end

    def validate_tags(tags, filters)
      values = []
      filters.each do |key, value|
        trueness = false
        logger.debug "Checking: #{key} for: #{value}"
        tags.each do |tag|
          if tag['key'] == key && tag['value'] == value
            trueness = true
            break
          end
        end
        values << trueness
      end
      # we're good if the results are all good
      values.all?
    end

    def get_capacity(asg_name)
      asg_client.describe_auto_scaling_groups({auto_scaling_group_names: \
        [asg_name] }).auto_scaling_groups.first.desired_capacity
    end

    def set_capacity(instance, options)
      template = {
        auto_scaling_group_name: instance.autoscalegroupname,
        desired_capacity: instance.change
      }

      logger.debug template
      asg_client.update_auto_scaling_group(template)
    end
  end
end
