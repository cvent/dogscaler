require 'aws-sdk'

module Dogscaler
  class AwsClient
    NoResultsError = Class.new(StandardError)
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
    def get_asg(asg_name=nil, asg_tag_filters = {})
      #asg_client.describe_auto_scaling_groups({auto_scaling_group_names: \
      #[asg_name] }).auto_scaling_groups.first
      next_token = nil
      autoscalegroups = []
      if asg_name.nil? and asg_tag_filters.empty?
        logger.error "Need a name or a filter set"
        exit 1
      end
      loop do
        body = {next_token: next_token}
        body['auto_scaling_group_names'] = [asg_name] if asg_name
        resp = asg_client.describe_auto_scaling_groups(body)
        asgs =  resp.auto_scaling_groups
        asgs.each do |instance|
          autoscalegroups << instance
        end
        next_token = resp.next_token
        break if next_token.nil?
      end
      if not asg_tag_filters.empty?
        res = []
        autoscalegroups.each do |group|
          if validate_tags(group.tags, asg_tag_filters)
            res << group
          end
        end
        raise NoResultsError if res.count == 0
        return res
      else
        return autoscalegroups
      end
    end
    def validate_tags(tags, filters)
      values = []
      filters.each do |key, value|
        trueness = false
        tags.each do |tag|
          logger.debug "Checking: #{key} for: #{value}"
          if tag['key'] == key
            logger.debug "Key: #{key} matches"
            logger.debug "Comparing: #{tag['value']} to: #{value}"
            if tag['value'] == value
              logger.debug "Value Matches"
              trueness = true
              break
            end
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
    def set_capacity(instance, desired_capacity, options)
      template = {
        auto_scaling_group_name: instance.autoscale_group,
        desired_capacity: desired_capacity,
      }
      logger.info "Updating autoscale group #{instance.autoscale_group}"
      logger.info "From current capacity: #{instance.capacity} to: #{desired_capacity}"
      if options[:dryrun]
        logger.info "Not updating due to dry run mode"
      	logger.debug template
      else
	    asg_client.update_auto_scaling_group(template)
	  end
    end
  end
end
