# solace-logging-config

This is a collection of logging configuration files made by Aaron for use with Solace PubSub+ event brokers and Solace Cloud services via Syslog forwarding.  Currently includes:


### Logging Rules

- rsyslog rules (RainerScript)
- syslog-ng rules
- logstash grok rules (ELK / ElasticSearch)


### Also includes:

- logrotate configuration
- cron example for log rotations
- (coming eventually) SEC (Simple Event Correlator) log correlation rules
- useful SEMP tool to grab logs remotely w/out Syslog config


## QuickStart - AWS & rsyslog

Quickly deploy a logging server for Solace in AWS **_for free_**!  Using one of the "free-tier" EC2 instances (e.g. t2.micro), and the pre-installed rsyslog.

### 1. Logging server

1. Boot / deploy an EC2 instance with Amazon Linux 2 AMI (HVM), t2.micro
     1. Edit the security group rules: add a TCP Custom rule for ports 51400-51422, from any Source: 0.0.0.0/0
     1. Once it's launched, take note of your EC2 instance Public IP address, we'll need this later
1. Login to EC2 instance using your generated key: `ssh -i <keyfile> ec2-user@<pubic-ip-addr>`
     1. Probably best practice to do a `sudo yum update` and `sudo yum upgrade` 
1. Download this repo: `wget https://github.com/aaron-613/solace-logging-config/archive/master.zip -q`
1. Unzip it: `unzip master.zip; rm master.zip; cd solace-logging-config-master`
1. Copy (or symlink?) rules file to /etc/rsyslog.d/: `sudo cp solace_rsyslog.conf /etc/rsyslog.d/`
1. Restart rsyslog: `sudo systemctl restart rsyslog`

### 2. Solace broker config

Then, we need to configure the Solace broker.

#### Solace Cloud

1. Login to Solace Cloud, Mission Control, Cluster Manager
1. Select the broker / service you wish to add logging to, click on "Manage"
1. Click on "Advanced Options" (top-right), "Syslog Forwarding": "Add"
    1. Give it a name (e.g. "external")
    2. Select all the Logs to forward
    3. Syslog Server hostname: enter the Public IP address from EC2 instance
    4. Port: 51400
    5. Protocol Type: TCCP

#### Solace Broker

1. Login to CLI.  Then:
```
enable
  config
    create syslog external
      facility event
      facility command
      facility system
      host <ec2-public-ip>:51400 transport tcp
      exit
    logging command all mode all-cmds
```

### 3. See the results!

On your logging server, head over to `/var/log/solace`, and you should start to see logs being populated there.  Try connecting a client app or something to your broker, and you should see that echoed in realtime to the `event.log`.


```
[ec2-user@ip-172-31-39-85 ~]$ cd /var/log/solace

[ec2-user@ip-172-31-39-85 solace]$ ls
sg-sol-3501-vmr  ip-172-25-199-45

[ec2-user@ip-172-31-39-85 solace]$ cd sg-sol-3501-vmr

[ec2-user@ip-172-31-39-85 sg-sol-3501-vmr]$ ls -lh
total 15M
-rw-r--r--. 1 root root  77K Apr 19 01:50 auth.log
-rw-r--r--. 1 root root 9.7M Apr 19 00:55 command.log
-rw-r--r--. 1 root root 3.1M Apr 19 01:50 event.log
-rw-r--r--. 1 root root  79K Apr 19 01:51 show.log
-rw-r--r--. 1 root root 1.1M Apr 19 01:48 show.log.1
-rw-r--r--. 1 root root 2.2K Apr 19 01:06 show.log.2.gz
-rw-r--r--. 1 root root 2.2K Apr 19 01:04 show.log.3.gz
-rw-r--r--. 1 root root  22K Apr 19 00:55 system.log
drwxr-xr-x. 2 root root   23 Apr 18 19:47 bw
drwxr-xr-x. 2 root root   23 Apr 18 19:47 default
drwxr-xr-x. 2 root root   23 Apr 19 00:46 rest

[ec2-user@ip-172-31-39-85 sg-sol-3501-vmr]$
```


## Supplied Functionality

The 3 different rules configurations for the different Syslog engines do basically the same thing:

- Listen on 3 different inbound TCP ports, one each for `dev`, `test`, and `prod`, because that's awesome/advanced!
  - rsyslog: 51400 (dev), 51401 (test), 51402 (prod)
  - syslog-ng: 51410 (dev), 51411 (test), 51412 (prod)
  - logstash: 51420 (dev), 51421 (test), 51422 (prod)
  - This way, I can add additional rules/processing/filtering later on depending on what port it is
    - e.g. Don't log VPN Bridge UP/DOWN events to the alerts.log for dev dev environments
    - e.g. Don't alert on SolCache DOWN events in dev if they come back up within 5 minutes
  - This assumes a particular Solace router is designated as prod, test, or dev.  Maybe change to prod/non-prod?
- Ability to process all 3 log facilities arriving from Solace, but does some filtering.  For each router, it creates a directory
for it prefixed by `router.`.  Then inside each:
  - `system.log`: this is essentially left alone, but I think this log is dumb as it's a subset of `event.log`
  - `command.log`: all the commands, but filtering out all the 'show' commands 
(which can be exported to command via the CLI command `en --> con --> logging command all mode all`.
Very useful for watching SEMP monitoring polling rate.
  - `show.log`: all of the show commands get put into a separate file to not junk up the `command.log`
  - `event.log`: all of the router's event logs, minus a couple AUTH logs that are constantly generated by SEMP monitoring apps
  - `auth.log`: the events corresponding to CLI/SEMP logins/lougouts
  - per-VPN event logging (optional): for VPN and CLIENT events, parse out the VPN name... this allows me to create per-VPN directories, and keep an event log only for that VPN.  This is very useful if other VPNs on the same appliance are very noisy and cause the main event log to roll quickly.
- Then I monitor the event logs for events of interest that are duplicated to a general `alerts.log` file.  This file would ideally 
be watched by a monitoring program, rather than having the monitoring program trying to watch every router's complete event log.


## Logrotate and Cron

Make sure your logs don't take up all your disk space!  There are some included files to make sure you rotate your log files, and check them periodically.

- Copy the `solace_logrorate` file into your `/etc/logrotate.d/` directory
- Copy the `solace_cron` file into `/etc/cron.d` directory
   - Or edit your crontab (`crontab -e`) and included the one-liner in there
 
*Make sure you edit/verify the paths, as specified in the files



## Syslog-NG

You might need EPEL installed first.

On AWS Linux, you'll need to install EPEL (extrams): `sudo amazon-linux-extras install epel -y`

Then you can copy the syslog_ng conf file into `/etc/syslog-ng/conf.d` --or-- replace `/etc/syslog-ng/syslog-ng.conf`.

## Logstash

https://www.elastic.co/guide/en/logstash/current/installing-logstash.html
