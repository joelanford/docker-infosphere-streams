#!/bin/bash

match_begin="begin streams environment"
match_end="end streams environment"

zkconnect="export STREAMS_ZKCONNECT=${STREAMS_ZKCONNECT:-zookeeper:2181}"
tags="export STREAMS_TAGS=${STREAMS_TAGS:-management,application}"
domain_id="export STREAMS_DOMAIN_ID=${STREAMS_DOMAIN_ID:-default}"
domain_ha="export STREAMS_DOMAIN_HA_COUNT=${STREAMS_DOMAIN_HA_COUNT:-1}"
instance_id="export STREAMS_INSTANCE_ID=${STREAMS_INSTANCE_ID:-default}"
instance_ha="export STREAMS_INSTANCE_HA_COUNT=${STREAMS_INSTANCE_HA_COUNT:-1}"

file="/etc/profile.d/streamsprofile.sh"

sed -i -e "/# $match_begin/,/# $match_end/c\# $match_begin\n$zkconnect\n$tags\n$domain_id\n$domain_ha\n$instance_id\n$instance_ha\n# $match_end" $file


source /etc/profile.d/streamsprofile.sh

running=1
trap '{ running=0; }' EXIT

function startup {
  echo "Setting up Infosphere Streams node..."
  streamtool registerdomainhost
  su streamsadmin -p -c 'streamtool mkdomain'
  su streamsadmin -p -c 'streamtool genkey'
  su streamsadmin -p -c 'streamtool chhost -a --tags ${STREAMS_TAGS} ${HOSTNAME}'
  su streamsadmin -p -c 'streamtool setdomainproperty domain.highAvailabilityCount=${STREAMS_DOMAIN_HA_COUNT}'
  su streamsadmin -p -c 'streamtool startdomain'
  echo "Infosphere Streams node setup complete."
}

startup
while (( running )); do
  sleep 1
done
