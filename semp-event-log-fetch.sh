#!/usr/bin/bash

# Aaron's Super Fantastic Solace event.log retriever using SEMPv1
#
# Copyright 2021 Solace Corporation. All rights reserved.
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


# how many lines to return
LINES_TO_SHOW=1000

# For Solace Cloud, find the admin/SEMP connection info in the Mission Control -> Cluster Manager -> "Manage" tab -> SEMP - REST API
# e.g. HOST=https://mr-abc123.messaging.solace.cloud:943  or  HOST=http://localhost:8080
HOST=
# e.g. MSG_VPN=cloud-demo-server  or  MSG_VPN=default
MSG_VPN=
# e.g. USERNAME=cloud-demo-server-admin  or  USERNAME=admin
USERNAME=
# e.g. PASSWORD=abc123  or  PASSWORD=admin
PASSWORD=


# if you just want to see messaging / vpn related logs, use this one:
SEMP="<rpc><show><log><event><lines/><num-lines>$LINES_TO_SHOW</num-lines><find/><search-string>: $MSG_VPN </search-string></event></log></show></rpc>"

# else, if you want to see ALL logs (system level, authentication checks, etc.) use this one:
#SEMP="<rpc><show><log><event><lines/><num-lines>$LINES</num-lines></event></log></show></rpc>"

# magic time..!
curl -u $USERNAME:$PASSWORD "$HOST/SEMP" -d "$SEMP" -s | grep log-entry | perl -pe ' s|\s*</?log-entry>||g; s/&lt;/</g; s/&gt;/>/g; '

if [ ${PIPESTATUS[0]} -ne 0 ]
then 
  echo "Something went wrong with curl, check your params again" >&2 
fi


# if you just want a simple one-liner to copy/paste, with no output manipulation, here you go:
# curl -u admin:admin "http://localhost:8080/SEMP" -d '<rpc><show><log><event><lines/><num-lines>1000</num-lines></event></log></show></rpc>' -s
