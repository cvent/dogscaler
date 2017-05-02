module Dogscaler
  class Config
    def generate
      config = <<-END
# Enter your datadog api credentials here:
datadog:
  api_key: KEYHERE
  application_key: KEYHERE
# This assumes you have a ~/.aws/credentials file, if you use multiple, you can specify which profile to use here.
aws:
  region: us-west-2
  profile: default
slack:
  channel: '#slack'
  api_token: TOKENHERE

# This is a list of events to check for. Each event will be checked on each run.
instances:
  'core':
    queries:
      - name: 'scale on cpu user'
        query: avg:system.cpu.user{env:production,type:core}
        scale_up_threshhold: 10    # scale up if the query surpasses this values
        scale_down_threshhold: 5   # scale down if the query goes below this value
        transform: avg             # What transform to use on the query, eg (min,max,last,avg,count)
    shrink_by: 1                   # How many instances to add to the autoscale group
    grow_by: 1                     # how many instances to remove from the autoscale group
    asg_tag_filters:               # key value tags of filter and find our autoscale group.
      Type: core
      Environment: production
  'mailer':
    queries:
      - name: 'scale on user invites'
        query: max:mailer.db.v3.unsent_invitations{*}
        scale_up_threshhold: 1
        scale_down_threshhold: 0
        transform: avg
    grow_by: 1
    shrink_by: 1
    asg_tag_filters:
      Type: mailer
      Environment: production
END
        puts config
      end
  end
end

