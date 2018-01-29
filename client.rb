#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'

require_relative 'config'

if ENV['DDNS_IFACE'].nil?
  puts 'Please set $DDNS_IFACE!'
  exit 1
end

def get_ip(iface)
  ip_output = `ip -6 a s #{iface}`
  ipv6_re = %r{inet6 (?<addr>.*?)\/64}
  ipv6_re.match(ip_output)['addr']
end

hostname = `hostname`.chomp
domain = `hostname -d`.chomp

conf = Config.new
if ENV['DDNS_DEBUG'].nil?
  ddns_server = conf.config['server']
  ddns_port   = conf.config['port']
else
  ddns_server = 'localhost'
  ddns_port   = 4567
end
http = Net::HTTP.new(ddns_server, ddns_port)
req = Net::HTTP::Post.new('/heartbeat')
req.body = JSON.dump(
  'hostname' => hostname,
  'domain' => domain,
  'target' => get_ip(ENV['DDNS_IFACE'])
)
http.request(req)
