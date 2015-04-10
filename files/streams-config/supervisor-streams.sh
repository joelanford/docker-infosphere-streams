#!/bin/bash

source /etc/profile.d/streamsprofile.sh

function begin {
  if [ $STREAMS_HOST_TYPE == "master" ]; then
    echo "Setting up Infosphere Streams master..."
    su - streamsadmin -c 'streamtool mkdomain'
    su - streamsadmin -c 'streamtool genkey'
    su - streamsadmin -c 'streamtool chhost -a --tags application,audit,authentication,jmx,management,sws,view $HOSTNAME'
    su - streamsadmin -c 'streamtool startdomain'
    su - streamsadmin -c 'streamtool mkinstance'
    su - streamsadmin -c 'streamtool startinstance'
    echo "Infosphere Streams master setup complete."
  elif [ $STREAMS_HOST_TYPE == "worker" ]; then
    echo "Setting up Infosphere Streams worker..."
    echo -n "Waiting for domain to be started..."
    su - streamsadmin -c 'streamtool lsdomain StreamsDomain | grep -i -q -s started' > /dev/null 2>&1
    while [ $? -ne 0 ]; do
      sleep 5
      echo -n "."
      su - streamsadmin -c 'streamtool lsdomain StreamsDomain | grep -i -q -s started' > /dev/null 2>&1
    done
    echo ""
    su - streamsadmin -c 'streamtool genkey'
    su - streamsadmin -c 'streamtool adddomainhost $HOSTNAME'
    su - streamsadmin -c 'streamtool chhost -a --tags application $HOSTNAME'
    echo -n "Waiting for instance to be started..."
    su - streamsadmin -c 'streamtool lsinstance --started StreamsInstance | grep -i -q -s StreamsInstance' > /dev/null 2>&1
    while [ $? -ne 0 ]; do
      sleep 5
      echo -n "."
      su - streamsadmin -c 'streamtool lsinstance --started StreamsInstance | grep -i -q -s StreamsInstance' > /dev/null 2>&1
    done
    echo ""
    su - streamsadmin -c 'streamtool addhost $HOSTNAME'
    echo "Infosphere Streams worker setup complete."
  fi
}
trap finish EXIT
function finish {
  if [ $STREAMS_HOST_TYPE == "master" ]; then
    su - streamsadmin -c 'streamtool stopinstance'
    su - streamsadmin -c 'streamtool rminstance --noprompt'
    su - streamsadmin -c 'streamtool stopdomain'
    su - streamsadmin -c 'streamtool rmdomain --noprompt'
  elif [ $STREAMS_HOST_TYPE == "worker" ]; then
    su - streamsadmin -c 'streamtool rmhost --noprompt $HOSTNAME'
    su - streamsadmin -c 'streamtool rmdomainhost --noprompt $HOSTNAME'
  fi
  exit
}
begin
sleep infinity
