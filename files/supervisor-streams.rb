#!/usr/bin/env ruby

require 'set'
require 'json'

class StreamsEnvironment
  def initialize(file)
    @file = file
  end

  def source
    Hash[ bash_env(". #{File.realpath @file}") - bash_env() ].each {|k,v| ENV[k] = v }
    self
  end

  def fixup
    profile = File.read(@file)
    profile.gsub!(
      /(# begin streams environment).*(# end streams environment)/m,
      [
        "# begin streams environment",
        "export STREAMS_ZKCONNECT=#{ENV["STREAMS_ZKCONNECT"] || "zookeeper:2181" }",
        "export STREAMS_TAGS=#{ENV["STREAMS_TAGS"] || "management,application" }",
        "export STREAMS_DOMAIN_ID=#{ENV["STREAMS_DOMAIN_ID"] || "default" }",
        "export STREAMS_DOMAIN_HA_COUNT=#{ENV["STREAMS_DOMAIN_HA_COUNT"] || "1" }",
        "export STREAMS_INSTANCE_ID=#{ENV["STREAMS_INSTANCE_ID"] || "default" }",
        "export STREAMS_INSTANCE_HA_COUNT=#{ENV["STREAMS_INSTANCE_HA_COUNT"] || "1" }",
        "# end streams environment"
      ].join("\n")
    )
    File.open(@file, "w") { |f| f.write(profile) }
    self
  end

  private
  def bash_env(cmd=nil)
    env = `#{cmd + ';' if cmd} printenv`
    env.split(/\n/).map {|l| l.split(/=/)}
  end
end

class Domain
  def initialize(id, etcd_url)
    @id = id
    @etcd_url = etcd_url.gsub(/\/\Z/, "")
  end

  def exist?
    get_domain_status != nil
  end

  def starting?
    get_domain_status == "starting"
  end

  def started?
    get_domain_status == "started"
  end

  def stopping?
    get_domain_status == "stopping"
  end

  def stopped?
    get_domain_status == "stopped"
  end

  def monitor
    Thread.start do
      while true
        domain = `su streamsadmin -p -c 'streamtool lsdomain #{@id}'`.split("\n").delete_if { |l| l.strip == "Id Status Owner Date" }[-1]
        if domain
          status = domain.strip.split(/\s+/)[1].downcase
          puts "UPDATING STATUS: #{status}"
          set_domain_status(status, 60)
        else
          puts "DOMAIN NOT FOUND - DELETING STATUS"
          delete_domain_status
        end
        sleep 45
      end
    end
  end
    


  def registerhost
    system("streamtool registerdomainhost -d #{@id}")
  end

  def create
    set_domain_status("creating", 30)
    system("su streamsadmin -p -c 'streamtool mkdomain -d #{@id}'") && set_domain_status("stopped")
  end

  def genkey
    system("su streamsadmin -p -c 'streamtool genkey -d #{@id}'")
  end

  def set_high_availability(value)
    system("su streamsadmin -p -c 'streamtool setdomainproperty -d #{@id} domain.highAvailabilityCount=#{value}'")
  end

  def get_high_availability
    `su streamsadmin -p -c 'streamtool getdomainproperty -d #{@id} domain.highAvailabilityCount'`.split("=")[1].to_i
  end

  def change_host_tags(host, tags)
    system("su streamsadmin -p -c 'streamtool chhost -d #{@id} --replace --noprompt --tags #{tags.to_a.join(",")} #{host}'")
  end

  def start
    set_domain_status("starting", 30)
    system("su streamsadmin -p -c 'streamtool startdomain -d #{@id}'") && set_domain_status("started", 30)
  end

  def stop
    set_domain_status("stopping", 30)
    system("su streamsadmin -p -c 'streamtool stopdomain -d #{@id}'") && set_domain_status("stopped")
  end

  def remove
    set_domain_status("removing", 30)
    system("su streamsadmin -p -c 'streamtool rmdomain -d #{@id} --noprompt'") && delete_domain_status
  end
  
  def unregisterhost
    system("streamtool unregisterdomainhost -d #{@id}")
  end

  private
  def set_domain_status(status, ttl=nil)
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@id}/status' -XPUT -d value=\"#{status}\" #{ttl ? "-d ttl=#{ttl}" : ""}"
    `#{command}`
  end

  def get_domain_status
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@id}/status'"
    result = JSON.parse(`#{command}`)["node"]
    result ? result["value"] : nil
  end

  def delete_domain_status
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@id}?dir=true&recursive=true' -XDELETE"
    `#{command}`
  end
end

class Instance
  def initialize(domain_id, id, etcd_url)
    @domain_id = domain_id
    @id = id
    @etcd_url = etcd_url.gsub(/\/\Z/, "")
  end
  
  def set_instance_status(status, ttl=nil)
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@domain_id}/instances/#{@id}/status' -XPUT -d value=\"#{status}\" #{ttl ? "-d ttl=#{ttl}" : ""}"
    `#{command}`
  end

  def get_instance_status
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@domain_id}/instances/#{@id}/status'"
    `#{command}`
  end

  def delete_instance_status
    command = "curl -s -L '#{@etcd_url}/v2/keys/services/infosphere-streams/domains/#{@domain_id}/instances/#{@id}?dir=true&recursive=true' -XDELETE"
    `#{command}`
  end

  def create
    set_instance_status("creating", 120)
    system("su streamsadmin -p -c 'streamtool mkinstance -d #{@domain_id} -i #{@id}'")
    set_instance_status("stopped")
  end

  def set_high_availability(value)
    system("su streamsadmin -p -c 'streamtool setproperty -d #{@domain_id} -i #{@id} instance.highAvailabilityCount=#{value}'")
  end

  def start
    set_instance_status("starting", 120)
    system("su streamsadmin -p -c 'streamtool startinstance -d #{@domain_id} -i #{@id}'")
    set_instance_status("started", 600)
  end

  def stop
    set_instance_status("stopping", 120)
    system("su streamsadmin -p -c 'streamtool stopinstance -d #{@domain_id} -i #{@id}'")
    set_instance_status("stopped")
  end

  def remove
    set_instance_status("removing", 120)
    system("su streamsadmin -p -c 'streamtool rminstance -d #{@domain_id} -i #{@id} --noprompt'")
    delete_instance_status
  end

  def join(host)
    system("su streamsadmin -p -c 'streamtool addhost -d #{@domain_id} -i #{@id} #{host}'")
  end
end

StreamsEnvironment.new("/etc/profile.d/streamsprofile.sh").fixup.source

host        = ENV["HOSTNAME"]
etcd_url    = ENV["ETCD_URL"]
domain_id   = ENV["STREAMS_DOMAIN_ID"]
domain_ha   = ENV["STREAMS_DOMAIN_HA_COUNT"]
instance_id = ENV["STREAMS_INSTANCE_ID"]
instance_ha = ENV["STREAMS_INSTANCE_HA_COUNT"]
tags = Set.new

domain = Domain.new(domain_id, etcd_url)
instance = Instance.new(domain_id, instance_id, etcd_url)

domain.registerhost
unless domain.exist?
  domain.create
  tags << "management"
end

domain.genkey
domain.monitor

ha = domain.get_high_availability
if ha < 3 && (domain.starting? || domain.started?)
  domain.set_high_availability(ha + 1)
  tags << "management"
end

domain.change_host_tags(host, tags)

unless domain.starting? || domain.started?
  domain.start
end


#instance.create
#instance.set_high_availability(instance_ha)
#instance.start
#instance.stop
#instance.remove

#domain.stop
#domain.remove
#domain.unregisterhost
