#!/bin/bash

source /etc/profile.d/streamsprofile.sh

STREAMS_TAGS=${STREAMS_TAGS:-management,application}
STREAMS_DOMAIN_ID=${STREAMS_DOMAIN_ID:-StreamsDomain}
STREAMS_DOMAIN_HA_COUNT=${STREAMS_DOMAIN_HA_COUNT:-1}
STREAMS_INSTANCE_ID=${STREAMS_INSTANCE_ID:-StreamsInstance}
STREAMS_INSTANCE_HA_COUNT=${STREAMS_INSTANCE_HA_COUNT:-1}

running=1
trap '{ running=0; }' EXIT

function startup {
  echo "Setting up Infosphere Streams node..."
  if ! streamtool lsdomain ${STREAMS_DOMAIN_ID} | grep -i -q -s ${STREAMS_DOMAIN_ID} > /dev/null 2>&1; then
    streamtool mkdomain
    streamtool genkey
    streamtool chhost -a --tags ${STREAMS_TAGS} ${HOSTNAME}
    streamtool setdomainproperty domain.highAvailabilityCount=${STREAMS_DOMAIN_HA_COUNT}
    streamtool startdomain
  else
    streamtool genkey
    echo -n "Waiting for domain ${STREAMS_DOMAIN_ID}..."
    while ! streamtool lsdomain ${STREAMS_DOMAIN_ID} | grep -i -q -s started > /dev/null 2>&1; do
      sleep 5
      echo -n "."
    done
    echo ""
    streamtool adddomainhost ${HOSTNAME}
    streamtool chhost -a --tags ${STREAMS_TAGS} ${HOSTNAME}
  fi
  if ! streamtool lsinstance ${STREAMS_INSTANCE_ID} | grep -i -q -s ${STREAMS_INSTANCE_ID} > /dev/null 2>&1; then
    streamtool mkinstance
    streamtool setinstanceproperty instance.highAvailabilityCount=${STREAMS_INSTANCE_HA_COUNT}
    streamtool startinstance
  else
    echo -n "Waiting for instance ${STREAMS_INSTANCE_ID}..."
    while ! streamtool lsinstance --started ${STREAMS_INSTANCE_ID} | grep -i -q -s ${STREAMS_INSTANCE_ID} > /dev/null 2>&1; do
      sleep 5
      echo -n "."
    done
    echo ""
    streamtool addhost ${HOSTNAME}
  fi
  echo "Infosphere Streams node setup complete."
}

startup
while (( running )); do
  sleep 1
done
