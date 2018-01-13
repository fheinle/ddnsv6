require 'sinatra'
require 'logger'
require 'json'
require 'yaml'

$config = YAML::load_file('ddnsv6.conf.yaml')

$LOG = Logger.new($config['logfile'], 'daily')

class ApiError < Exception
end

error ApiError do
  "API error: #{env['sinatra.error'].message}"
end

post '/heartbeat' do
  $LOG.debug("Heartbeat from #{params['hostname']}")
  data = JSON.parse request.body.read
  %w[hostname domain target].each do |arg|
    raise ApiError, 'Missing arguments' unless data.include? arg
  end
  raise ApiError, 'Invalid hostname' if data['hostname'].include? '.'
  raise ApiError, 'Invalid domain' unless $config['domains'].include? data['domain']
  raise ApiError, 'Invalid target IPv6' unless data['target'].include? ':'
  host = Hostname.new(data['hostname'], data['domain'])
  if host.update(data['target'])
    'success'
  else
    'fail'
  end
end

class Hostname
  def initialize(hostname, domain)
    @hostname = hostname
    @domain = domain
    @data_file = File.join($config['basedir'], @domain, @hostname) << '.conf'
  end

  def timestamp
    if File.exist? data_file
      File.new(@data_file).mtime
    else
      Nil
    end
  end

  def update(target_ip)
    raise ApiError 'Invalid target IPv6' unless target_ip.include? ':'

    File.open(@data_file, 'w') do |f|
      f.write(target_ip.chomp)
    end
  end
  true
end

Dir.mkdir $config['basedir'] unless File.directory? $config['basedir']

$config['domains'].each do |domain|
  dir_path = File.join($config['basedir'], domain)
  Dir.mkdir dir_path unless File.directory? dir_path
end
