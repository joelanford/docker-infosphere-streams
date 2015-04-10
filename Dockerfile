FROM centos:7
MAINTAINER Joe Lanford <joe.lanford@gmail.com>

#
#  Notes
# -------
#
#   During development, I found it was easiest to split my images and builds
#   up into three steps.
#
#   In the first step, I start from the base CentOS 7 image and install some
#   core Linux utilities. I can reuse this image for ALL of my other projects
#
#   In the second step, I add the InfoSphere Streams tar.gz file (downloaded
#   directly form the IBM website), install the Streams dependencies, create
#   the streamsadmin user, and run the Streams installer. This is a good
#   stopping point for this image because tweaks in step 3 are costly to
#   build due to the time it takes to load the build context for this step
#
#   In the third step, I add the supervisor configurations and scripts that
#   enable easy spin up and spin down of one or more docker containers for
#   this image to build virtual clusters.
#


##############################################
#                                            #
# Step 1: Base setup of some core utilities. #
#                                            #
##############################################
RUN yum clean all                                 && \
    yum install -y sudo                              \
                   openssh-server                    \
                   openssh-clients                   \
                   rsyslog                           \
                   passwd                            \
                   python-setuptools                 \
                   bind-utils                     && \
    rm -rf /var/cache/*                           && \
    /usr/bin/ssh-keygen -A                        && \
    easy_install pip                              && \
    pip install supervisor                        && \
    echo_supervisord_conf > /etc/supervisord.conf && \
    mkdir /etc/supervisord.d/                     && \
    printf "[include]\nfiles = /etc/supervisord.d/*.conf\n" >> /etc/supervisord.conf

ADD files/os-base/supervisor-sshd.conf /etc/supervisord.d/sshd.conf
ADD files/os-base/supervisor-rsyslog.conf /etc/supervisord.d/rsyslog.conf
ADD files/os-base/rsyslog.conf /etc/rsyslog.conf

EXPOSE 22
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]



##################################################
#                                                #
# Step 2: Install the InfoSphere Streams product #
#                                                #
##################################################

# Add in the InfoSphere Streams software
ADD files/streams-base/Streams-QuickStart-4.0.0.0-x86_64-el7.tar.gz /tmp/

# Instal InfoSphere Streams prerequisites
RUN yum install -y tar                         \
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
                   java-1.7.0-openjdk-devel && \
    rm -rf /var/cache/*

# Create user for InfoSphere Streams
RUN adduser streamsadmin                                                && \
    echo "passw0rd" | passwd streamsadmin --stdin                       && \
    echo 'streamsadmin ALL=NOPASSWD: ALL' > /etc/sudoers.d/streamsadmin

# Setup the environment variables
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install it!
ADD files/streams-base/installer.properties /tmp/StreamsInstallFiles/
ADD files/streams-base/streamsprofile.sh /etc/profile.d/
RUN /bin/bash -l -c '/tmp/StreamsInstallFiles/InfoSphereStreamsSetup.bin' && \
    rm -rf /tmp/StreamsInstallFiles

# Expose the SWS Port
EXPOSE 8443



#################################################
#                                               #
# Step 3: Add InfoSphere Streams configurations #
#                                               #
#################################################

ADD files/streams-config/supervisor-streams.sh /opt/ibm/InfoSphere_Streams/4.0.0.0/bin/supervisor-streams.sh
ADD files/streams-config/streams.conf /etc/supervisord.d/streams.conf


