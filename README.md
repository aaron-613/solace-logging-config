# solace-logging-config

This is a collection of logging configuration files for use with Solace messaging routers.  Currently includes:

 - rsyslog
 - syslog-ng
 - logstash grok (ELK / ElasticSearch)
 
_These are very much WIP, and meant to give a Solace administrator a head-start on configuration._

I have all 3 of these running concurrently on my local dev server, hence the port variations.

Divide the inbound ports into: dev, test, and prod.  This could allow for future variations in rules/processing.


I've also included an example logrotate configuration file, and a crontab entry to check every 5 minutes if the logs need rotating

