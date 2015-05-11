FROM joelanford/centos7
MAINTAINER Joe Lanford <joe.lanford@gmail.com>

# Add in the InfoSphere Streams software
ADD files/InfoSphere_Streams_4.0.0.0.tar.gz /opt/ibm/

# Install InfoSphere Streams prerequisites
RUN yum install -y tar                         \
                   ruby                        \
                   gcc                         \
                   gcc-c++                     \
                   initscripts                 \
                   libcurl-devel               \
                   libxslt                     \
                   perl-Time-HiRes             \
                   perl-XML-Simple             \
                   unzip                       \
                   which                       \
                   xdg-utils                   \
                   zip                         \
                   java-1.7.0-openjdk-devel || \
    yum clean all                           && \
    rm -rf /var/cache/*

# Create user for InfoSphere Streams
RUN adduser streamsadmin                                                && \
    echo "passw0rd" | passwd streamsadmin --stdin                       && \
    echo 'streamsadmin ALL=NOPASSWD: ALL' > /etc/sudoers.d/streamsadmin

# Setup the environment variables
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ADD files/streamsprofile.sh /etc/profile.d/
ADD files/streams.conf /etc/supervisor.d/streams.conf
ADD files/supervisor-streams.sh /opt/ibm/InfoSphere_Streams/4.0.0.0/bin/supervisor-streams.sh
ADD files/supervisor-streams.rb /opt/ibm/InfoSphere_Streams/4.0.0.0/bin/supervisor-streams.rb

# Expose the SWS Port
EXPOSE 8443
