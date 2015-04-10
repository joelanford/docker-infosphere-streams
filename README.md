# docker-infosphere-streams
docker-infosphere-streams is a container definition that is used to manage the lifecycle of a simple InfoSphere Streams docker cluster on a single host.  Rake is used to quickly, easily, and repeatably invoke docker commands to build and run the cluster of containers. 

The container includes supervisord and associated configurations to manage the services that run in the container:
* An SSH server is installed and exposed for ease of administration.
* Rsyslog is installed and configured to capture system logs in /var/log.
* A simple InfoSphere streams service script is installed to start and stop services for master and worker nodes.

## Prerequisites
1. Docker: https://github.com/docker/docker
2. Rake: https://github.com/ruby/rake
3. InfoSphere Streams 4.0.0.0 (choose the EL7 native installation package): http://www-01.ibm.com/software/data/infosphere/streams/quick-start/ 

## Setup
1. Check out the repository.

  ```shell
  git clone https://github.com/joelanford/docker-infosphere-streams.git
  ```

2. Move the InfoSphere Streams 4.0.0.0 native installation package into place

  ```shell
  mv /path/to/Streams-QuickStart-4.0.0.0-x86_64-el7.tar.gz ./docker-infosphere-streams/files/streams-base
  ```

3. Build the image

  ```shell
  cd docker-infosphere-streams
  rake
  ```

4. Configure docker for Automatic DNS (necessary for cluster communication among InfoSphere Streams nodes). See https://github.com/rehabstudio/docker-autodns#prerequisites.

## Running the container(s): `rake run`
* By default, `rake run` will start zookeeper, autodns, a single master, and three workers
* You can override the default number of nodes by invoking rake run with an argument: `rake run[3]`

## Accessing the cluster

The image contains a default username and password to help you get started.  Make sure to change the password for increased security.  This username and password can be used for SSH and access to the InfoSphere Streams web console
* Username: streamsadmin
* Password: passw0rd

### SSH
To find the SSH port exposed on the host for a particular container, inspect the output of `docker ps` in the PORTS column. Invoke ssh on the host with that port to access the node

  ```
  ssh streamsadmin@<docker_host> -p <ssh_mapped_port>
  ```

### Web Console
Once you've started a cluster, you can load the Streams Console web interface in a browser at [https://\<docker_host\>:8443/streams/domain/console](https://\<docker_host\>:8443/streams/domain/console)

## Helpful Tips
* When supervisor starts the streams service when the container starts, it logs output to /var/log/supervisor-streams.log.  This log file can be helpful in debugging problems on the master with the creation and start phases of the domain and instance as well as on the workers with their registration with the domain and addition of themselves to the instance.
* You can safely stop a single worker and it will remove itself from the instance prior to shutting down.  Make sure to pass a timeout to the docker stop command to give the service enough time for it to cleanly exit (e.g. `docker stop -t 90 streams-4`)

