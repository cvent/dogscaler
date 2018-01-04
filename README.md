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
### Datadog API

Within datadog, you need to generate an application key and also include your api key. You can find this information from 
Integrations -> Api


### Amazon Permissions

Create a set of credentials in IAM and give them access to:
Autoscale -> DescribeAutoscaleGroups and
Autoscale -> UpdateAutoscaleGroups

These permissions are used to lookup autoscale groups, check their size and updated the desired number of instances.


### Config File
Create a dogscaler.yaml file with contents like:

```

  datadog:
    api_key: <KEYHERE>
    application_key: <KEYHERE>
  aws:
    region: 'us-west-2'
    profile: 'main'  # This expects a .aws/credentials file with a section matching this name
  slack:
    channel: '#production'
    api_token: 'token_here'

instances:
  'mailer_prod':
    queries:
      - name: unsent_invites
        query: max:mail.db.v3.unsent_invitations{*}
        scale_up_threshhold: 1500
        scale_down_threshhold: 20
        transform: avg
      - name: mailer load
        query: avg:system.cpu.user{env:production,type:mailer}
        scale_up_threshhold: 75
        scale_down_threshhold: 20
        transform: avg
    asg_tag_filters:
      Type: mailer
      Environment: production
    grow_by: 1
    shrink_by: 1
    cooldown_period: 240
  'web_prod':
    queries:
      - name: web load
        query: avg:system.cpu.user{env:production,type:web}
        scale_up_threshhold: 75
        scale_down_threshhold: 20
        transform: avg
    asg_tag_filters:
      Type: web
      Environment: production
    grow_by: 2
    shrink_by: 1
    cooldown_period: 240
```

## Usage


Below are some simple examples

Help output:

```bash
dogscaler help
Commands:
  dogscaler apply           # Scale the environment based on a query
  dogscaler config          # Generate a default configuration
  dogscaler debug           # testing command, describes the query it ran and the results
  dogscaler help [COMMAND]  # Describe available commands or one specific command

Options:
  d, [--debug=Enable debug mode], [--no-debug]
  r, [--region=AWS Region]
                                                 # Default: us-west-2
  v, [--verbose=Verbose Output], [--no-verbose]
  t, [--terse=Terse Output], [--no-terse]
      [--dryrun=Do a dry run], [--no-dryrun]
      [--config=Path to configuration file]
```

The basic example - Apply the configuration.

```
  $ dogscaler apply --config dogscaler.yaml
```

Test the configuration without making changes, with verbose output:

```bash
$ dogscaler apply --dryrun -v --config dogscaler.yaml
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


