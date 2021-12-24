# solace-logging-config

This is a collection of logging configuration files for use with Solace messaging routers.  Currently includes:


### Logging Rules

- rsyslog rules (RainerScript)
- syslog-ng rules
- logstash grok rules (ELK / ElasticSearch)


### Also include

- logrotate configuration
- crontab logrotate example
- (coming eventually) SEC (Simple Event Correlator) log correlation rules


## QuickStart - AWS

Quickly deploy a logging server for Solace in AWS **_for free_**!  Using one of the "free-tier" EC2 instances (e.g. t2.micro).
1. Boot / deploy an EC2 instance with Amazon Linux 2 AMI (HVM)
_a) Edit the security group rules: add a TCP Custom rule for ports 51400-51422, from any Source: 0.0.0.0/0
_b) Once it's launched, take note of your EC2 instance Public IP address, we'll need this later
1. Login to EC2 instance using your generated key: `ssh -i <keyfile> ec2-user@<pubic-ip-addr>`
1. Clone or download this repo:
```
git clone https://github.com/aaron-613/solace-logging-config.git
 ** OR **
wget https://github.com/aaron-613/solace-logging-config/archive/master.zip -q; unzip master.zip; rm master.zip
```
4. Use the rsyslog rules, since rsyslog is already installed and running in AWS Linux. Copy, or better yet link, the rules into the right directory: `ln solace_rsyslog.conf /etc/rsyslog.d/`
1. Restart rsyslog: `sudo systemctl restart rsyslog`

Then, we need to configure the Solace broker.


## Supplied Functionality

The rules configurations do basically the same thing:

- Listen on 3 different inbound TCP ports, one for dev, test, and prod:
  - 51400,51401,51402 for rsyslog; 51410,51411,51412 for syslog-ng; 51420,51421,51422 for logstash
  - This way I could add additional rules/processing later on depending on what port it is
    - e.g. Don't log VPN Bridge UP/DOWN events to the alerts.log for dev dev environments
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
  - For VPN and CLIENT events, parse out the VPN name... this allows me to create per-VPN directories
  (prefixed with `vpn.`), and keep an event log only for that VPN.  This is very useful if other VPNs on the same appliance
  are very noisy and cause the main event log to roll quickly.
- Then I monitor the event logs for events of interest that are duplicated to a general `alerts.log` file.  This file would ideally 
be watched by a monitoring program, rather than having the monitoring program trying to watch every router's complete event log.

I've also included an example logrotate configuration file, and a crontab entry to check every 2 minutes if the logs need rotating.

## Directory contents

This is what a particular router's directory would look like:

```
[alee@sg-sol-3501-host router.sg-sol-3501-vmr]$ ls -lh
total 15M
-rw-r--r--. 1 root root  77K Apr 19 01:50 auth.log
-rw-r--r--. 1 root root 9.7M Apr 19 00:55 command.log
-rw-r--r--. 1 root root 3.1M Apr 19 01:50 event.log
-rw-r--r--. 1 root root  79K Apr 19 01:51 show.log
-rw-r--r--. 1 root root 1.1M Apr 19 01:48 show.log.1
-rw-r--r--. 1 root root 2.2K Apr 19 01:06 show.log.2.gz
-rw-r--r--. 1 root root 2.2K Apr 19 01:04 show.log.3.gz
-rw-r--r--. 1 root root  22K Apr 19 00:55 system.log
drwxr-xr-x. 2 root root   23 Apr 18 19:47 vpn.bw
drwxr-xr-x. 2 root root   23 Apr 18 19:47 vpn.default
drwxr-xr-x. 2 root root   23 Apr 19 00:46 vpn.rest
[alee@sg-sol-3501-host router.sg-sol-3501-vmr]$
```
