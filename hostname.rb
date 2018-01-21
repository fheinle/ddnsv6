require 'fileutils'
require 'yaml'
require 'ipaddr'

require_relative 'config'

# represent a hostname
# does not need to have an IP associated with after initialization
class Hostname
  attr_reader :hostname
  attr_reader :domain
  attr_reader :current_ip
  attr_reader :current_timestamp

  def initialize(hostname, domain)
    conf = Config.new
    raise 'Hostname has a dot in it' if hostname.include? '.'
    raise "Unknown domain: #{domain}" unless conf.config['domains'].include? domain

    @data_file = File.join(
      conf.config['basedir'],
      domain, hostname
    ) << '.dns.yaml'
    @hostname = hostname
    @domain = domain
    @current_ip         = read_from_yaml('current_ip')
    @current_timestamp  = read_from_yaml('current_timestamp')
  end

  def update(target_ip)
    new_ip = IPAddr.new target_ip
    @current_ip        = new_ip.to_s
    @current_timestamp = Time.now
    save_to_yaml
  end

  def read_from_yaml(attribute)
    YAML.load_file(@data_file)[attribute] if File.exist? @data_file
  end
  private :read_from_yaml

  def save_to_yaml
    domain_directory = File.dirname(@data_file)
    FileUtils.mkdir_p domain_directory unless Dir.exist? domain_directory
    File.open(@data_file, 'w') do |f|
      f.write(YAML.dump(
                'current_timestamp'     => @current_timestamp,
                'current_ip'            => @current_ip,
      ))
    end
  end
  private :save_to_yaml

  def to_s
    "Domain: #{@domain} Host: #{@hostname}"
  end
end

def get_hostname_from_file(fname)
  conf = Config.new
  raise 'Absolute path required' unless fname.start_with? conf.config['basedir']
  domain = fname.sub("#{conf.config['basedir']}/", '').split('/')[0]
  hostname = fname.sub("#{domain}/", '').sub('.dns.yaml', '')
  Hostname.new(hostname, domain)
end

def get_hostnames_in_domain(domain_name)
  conf = Config.new
  raise 'Domain not found' unless conf.config['domains'].include? domain_name
  domain_dir = File.join(conf.config['basedir'], domain_name)
  host_files = Dir.glob(File.join(domain_dir, '*.dns.yaml'))
  hosts = []
  host_files.each do |host_file|
    host = get_hostname_from_file(host_file)
    hosts.push(host)
  end
  hosts
end

def get_domains
  conf = Config.new
  domain_files = Dir.glob(File.join(conf.config['basedir'], '*'))
  domains = []
  domain_files.each do |domain|
    domains.push(
      domain_only(domain)
    )
  end
  domains
end

def domain_only(path)
  conf = Config.new
  basedir = "#{conf.config['basedir']}/"
  path.sub(basedir, '').delete('/')
end

def get_all_hosts
  hosts = {}
  get_domains.each do |domain|
    hosts[domain] = get_hostnames_in_domain(domain)
  end
  hosts
end
