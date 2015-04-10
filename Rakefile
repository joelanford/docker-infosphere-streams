task default: %w[build]

desc "cleanup old/existing containers"
task :clean do
  containers = `docker ps -a`.split("\n")
  containers.each do |container|
    names = container.split(/\s+/).last.split(",")
    names.each do |name|
      case name
      when "zookeeper", "autodns", /\Astreams-\d+\Z/
        sh "docker rm -f #{name}"
      end
    end
  end
end

desc "setup infosphere streams prereqs"
task :prereqs do
  sh "docker run -d -h zookeeper --name zookeeper -p 2181:2181 jplock/zookeeper"
  sh "docker run -d -h autodns --name autodns -p 0.0.0.0:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock rehabstudio/autodns"
end

desc "start an infosphere streams cluster"
task :run, [:nodes] => [:clean, :prereqs] do |t,args|
  nodes = args[:nodes] ? args[:nodes].to_i : 4
  1.upto(nodes) do |i|
    # Start an image.  streams-1 is a master and streams-x (where x>1) is a worker
    sh "docker run -d -h streams-#{i} --name streams-#{i} --privileged #{i==1 ? "-p 8443:8443" : ""} -p 22 --env STREAMS_HOST_TYPE=#{i==1 ? "master" : "worker"} joe.lanford/infosphere-streams"

    # This seems to be necessary to get the autodns to successfully register each container as it comes up
    sleep 1
  end
end

desc "build the docker image"
task :build do
  sh "docker build -t joe.lanford/infosphere-streams ."
end

