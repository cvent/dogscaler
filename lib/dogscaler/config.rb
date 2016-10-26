module Dogscaler
  class Config
    def generate
      config = <<-END
# Enter your datadog api credentials here:
datadog:
  api_key:
  application_key:
# This assumes you have a .aws/credentials file, if you use multiple, you can specify which profile to use here.
aws:
  region: 'us-west-2'
  profile: 'default'

# This is a list of events to check for. Each event will be checked on each run.
instances:
  -
    name: 'instance1'
    query: "example datadog query: eg max:system.load.1{env:production}"
    autoscale_group: "Name of an autoscale group to scale"
    scale_up_threshhold: 75   # scale up if the query surpasses this values
    scale_down_threshhold: 20 # scale down if the query goes below this value
    min_instances: 3          # Minimum number of systems to have in the autoscale group
    max_instances: 5          # Maximum number of systems to have in the autoscale group
    grow_by: 2                # How many instances to add to the autoscale group
    shrink_by: 1              # how many instances to remove from the autoscale group
    transform: min            # What transform to use on the query, eg (min,max,last,avg,count)
  -
    name: 'instance2'
    query: "example datadog query: eg max:system.load.1{env:production}"
    autoscale_tag_filters:      # Alternatively use a set of tags to find your instance
      - Name: nginx             # name is key,  "nginx" is the tag Value
      - Environment: Production # Environment is the key, production is the value
    scale_up_threshhold: 100    # scale up if the query surpasses this values
    scale_down_threshhold: 40   # scale down if the query goes below this value
    min_instances: 3            # Minimum number of systems to have in the autoscale group
    max_instances: 5            # Maximum number of systems to have in the autoscale group
    grow_by: 2                  # How many instances to add to the autoscale group
    shrink_by: 1                # how many instances to remove from the autoscale group
    transform: avg              # What transform to use on the query, eg (min,max,last,avg,count)

END
      puts config
      end
  end
end

