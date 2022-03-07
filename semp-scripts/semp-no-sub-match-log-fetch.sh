#!/usr/bin/bash

# Aaron's Super Fantastic Solace "No Subscription Match" log retriever using SEMPv1
#
# This will log shows topics, publishers, and timestamps of messages that were
# published that nobody was subscribed to.  Very useful for tracking down 
# rogue publishers.
#
#         <timestamp>2022-01-18T17:20:42+00:00</timestamp>
#         <client-name>AaronsThinkPad3/4926/#00000001/-8-rZFWr2k</client-name>
#         <client-username>default</client-username>
#         <vpn-name>default</vpn-name>
#         <topic>bbbb/bbbb/bbbb/001367</topic>
#
#
# Copyright 2021-2022 Solace Corporation. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.


# For Solace Cloud, find the admin/SEMP connection info in the Mission Control -> Cluster Manager -> "Manage" tab -> SEMP - REST API
# e.g. HOST=https://mr-abc123.messaging.solace.cloud:943  or  HOST=http://localhost:8080
HOST=
# e.g. MSG_VPN=cloud-demo-server  or  MSG_VPN=default
MSG_VPN=
# e.g. USERNAME=cloud-demo-server-admin  or  USERNAME=admin
USERNAME=
# e.g. PASSWORD=abc123  or  PASSWORD=admin
PASSWORD=

# SEMPv1 command equivalent to 'show log no-subscription-match wide'
SEMP="<rpc><show><log><no-subscription-match><wide/></no-subscription-match></log></show></rpc>"

# magic time..!
curl -u $USERNAME:$PASSWORD "$HOST/SEMP" -d "$SEMP" -s | grep log-entry | perl -pe ' s|\s*</?log-entry>||g; s/&lt;/</g; s/&gt;/>/g; '

if [ ${PIPESTATUS[0]} -ne 0 ]
then 
  echo "Something went wrong with curl, check your params again" >&2 
fi


# if you just want a simple one-liner to copy/paste, with no output manipulation, here you go:
# curl -u admin:admin "http://localhost:8080/SEMP" -d '<rpc><show><log><no-subscription-match><wide/></no-subscription-match></log></show></rpc>' -s
