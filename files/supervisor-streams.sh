#!/bin/bash

source /etc/profile.d/streamsprofile.sh
export HOME=/home/streamsadmin

function begin {
  if [ $STREAMS_HOST_TYPE == "master" ]; then
    echo "Setting up Infosphere Streams master..."
    streamtool mkdomain
    streamtool genkey
    streamtool chhost -a --tags application,audit,authentication,jmx,management,sws,view $HOSTNAME
    streamtool startdomain
    streamtool mkinstance
    streamtool startinstance
    echo "Infosphere Streams master setup complete."
  elif [ $STREAMS_HOST_TYPE == "worker" ]; then
    echo "Setting up Infosphere Streams worker..."
    echo -n "Waiting for domain to be started..."
    streamtool lsdomain StreamsDomain | grep -i -q -s started > /dev/null 2>&1
    while [ $? -ne 0 ]; do
      sleep 5
      echo -n "."
      streamtool lsdomain StreamsDomain | grep -i -q -s started > /dev/null 2>&1
    done
    echo ""
    streamtool genkey
    streamtool adddomainhost $HOSTNAME
    streamtool chhost -a --tags application $HOSTNAME
    echo -n "Waiting for instance to be started..."
    streamtool lsinstance --started StreamsInstance | grep -i -q -s StreamsInstance > /dev/null 2>&1
    while [ $? -ne 0 ]; do
      sleep 5
      echo -n "."
      streamtool lsinstance --started StreamsInstance | grep -i -q -s StreamsInstance > /dev/null 2>&1
    done
    echo ""
    streamtool addhost $HOSTNAME
    echo "Infosphere Streams worker setup complete."
  fi
}
trap finish EXIT
function finish {
  if [ $STREAMS_HOST_TYPE == "master" ]; then
    streamtool stopinstance
    streamtool rminstance --noprompt
    streamtool stopdomain
    streamtool rmdomain --noprompt
  elif [ $STREAMS_HOST_TYPE == "worker" ]; then
    streamtool rmhost --noprompt $HOSTNAME
    streamtool rmdomainhost --noprompt $HOSTNAME
  fi
  exit
}
begin
sleep infinity
