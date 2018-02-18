#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'config'
require_relative 'hostname'

require 'cloudflare'
require 'journald/logger'

$log = Journald::Logger.new('ddnsv6::worker')

def new_host(host, zone)
  new_host_data = {
    type:    'AAAA',
    ttl:     120,
    name:    host.hostname,
    content: host.current_ip
  }
  zone.dns_records.post(new_host_data.to_json,
                        content_type: 'application/json')
end

def update_host(host_in_cf, host)
  settings = Config.new
  if settings.config['whitelist'].include? "#{host.hostname}.#{host.domain}"
    host_in_cf.update_content(host.current_ip)
  else
    $log.debug "Ignoring host #{host.hostname}.#{host.domain}, not whitelisted"
  end
end

def update_zone(zone)
  hosts = get_hostnames_in_domain(zone.record[:name])
  aaaa_records = zone.dns_records.all.delete_if { |rec| rec.record[:type] != 'AAAA' }
  hosts.each do |host|
    host_in_cf = aaaa_records.detect { |rec| rec.record[:name] == "#{host.hostname}.#{host.domain}"}
    if host_in_cf.nil?
      $log.info "New host #{host.hostname}.#{host.domain}"
      new_host(host, zone)
    elsif host_in_cf.record[:content] != host.current_ip
      $log.info "Update host #{host.hostname}.#{host.domain}"
      update_host(host_in_cf, host)
    else
      $log.debug "Up-to-date host #{host.hostname}.#{host.domain} left alone"
    end
  end
end

get_domains.each do |domain|
  settings = Config.new
  cloudflare_connection = Cloudflare.connect(email: settings.config['cloudflare_email'],
                                             key: settings.config['cloudflare_key'])
  zone = cloudflare_connection.zones.find_by_name(domain)
  if zone.nil?
    $log.error "Ignoring domain #{domain}, not managed on CloudFlare"
  else
    update_zone(zone)
  end
end
