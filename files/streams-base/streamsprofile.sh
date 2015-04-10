export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export STREAMS_ZKCONNECT=zookeeper:2181

if [ -e /opt/ibm/InfoSphere_Streams/4.0.0.0/bin/streamsprofile.sh ]; then
  source /opt/ibm/InfoSphere_Streams/4.0.0.0/bin/streamsprofile.sh
fi
