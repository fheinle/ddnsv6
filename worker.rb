#!/usr/bin/env ruby
require_relative 'config'
require_relative 'hostname'

require 'yaml'
require 'cloudflare'

settings = Config.new
cloudflare_connection = Cloudflare.connect(email: settings.config['cloudflare_email'],
                                           key: settings.config['cloudflare_key'])

get_domains.each do |domain|
  zone =  cloudflare_connection.zones.find_by_name(domain)
  if zone.nil?
    puts "Domain #{domain} not managed by CloudFlare!"
    exit 1
  end
  hosts = get_hostnames_in_domain(domain)
  aaaa_records = zone.dns_records.all.delete_if { |rec| rec.record[:type] != 'AAAA' }
  hosts.each do |host|
    host_in_cf = aaaa_records.detect { |rec| rec.record[:name] == "#{host.hostname}.#{host.domain}"}
    if host_in_cf.nil?
      update_host(host_in_cf, host)
    elsif host_in_cf.record[:content] != host.current_ip
      update_host(host_in_cf, host)
    end
  end
end