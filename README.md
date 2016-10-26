Dogscaler
=======================
Dogscaler was written to scale up autoscale groups based on the results of a 
datadog query.

## Installation
Installation is easy just as any other gem:

```bash
gem install dogscaler

```

## Configuration
Create a dogscaler.yaml file with contents like:

```

  datadog:
    api_key: <KEYHERE>
    application_key: <KEYHERE>
  aws:
    region: 'us-west-2'
    profile: 'main'  # This expects a .aws/credentials file with a section matching this name
  instances:
    -
      name: 'nginx waiting in dev'               # name/description for what this scaling instance event is called.
      query: "max:nginx.net.waiting{env:dev}"    # Datadog metric to query
      autoscale_group: "dev"        # Static name of autoscale group to scale  
      scale_up_threshhold: 75       # Theshold to scale if the data returned is greater
      scale_down_threshhold: 20     # Threshold to scale down if the data is less 
      grow_by: 2                    # How many instances to increase
      shrink_by: 1                  # how many instances to decrease
      transform: avg                # transform on the datapoints returned from the datadog event.
  
    -
      name: 'nginx waiting in prod'
      query: "max:nginx.net.waiting{env:production}"
      asg_tag_filters:              # instead of using a static autoscale group name, you can use tags and filter by them instead
        Type: web                   # This is a key/value pair of aws tags on the autoscale group
        Environment: production     # Multiple tags are concatenated together to filter/reduce instances
      scale_up_threshhold: 10
      scale_down_threshhold: 5
      grow_by: 2
      shrink_by: 1
      transform: avg

```

## Usage


Below are some simple examples

The basic example - Apply the configuration.

```
  $ dogscaler apply -c dogscaler.yaml
```

Test the configuration without making changes, with verbose output:

```bash
$ dogscaler apply --dryrun -v -c dogscaler.yaml
INFO -- : Value: 147.01052631578946 Threshold: 75.
INFO -- : Would scale up by 2 instances.
INFO -- : Value: 147.01052631578946 Threshold: 75.
INFO -- : Would scale up by 2 instances.
INFO -- : Updating autoscale group production
INFO -- : From current capacity: 1 to: 2
INFO -- : Not updating due to dry run mode
INFO -- : Value: 3.0 Threshold: 5.
INFO -- : Would scale down by 1 instances.
INFO -- : Would have reduced capacity of production-web but already at minimum.
INFO -- : Current desired: 3
INFO -- : Current min: 3
```


