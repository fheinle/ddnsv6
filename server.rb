#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra/base'
require 'journald/logger'
require 'json'
require 'yaml'

require_relative 'hostname'
require_relative 'config'

class ApiAPP < Sinatra::Base
  def initialize
    @log = Journald::Logger.new('ddnsv6')
    @conf = Config.new
  end
  error RuntimeError do
    [409, JSON.dump(msg => "API error: #{env['sinatra.error'].message}")]
  end

  post '/heartbeat' do
    @log.debug "Heartbeat from #{request.ip}"
    data = JSON.parse(request.body.read)
    %w[hostname domain target].each do |arg|
      raise 'Missing arguments' unless data.include? arg
    end
    raise 'Invalid hostname' if data['hostname'].include? '.'
    raise 'Invalid domain' unless @conf.config['domains'].include? data['domain']
    raise 'Invalid target IPv6' unless data['target'].include? ':'
    host = Hostname.new(data['hostname'], data['domain'])
    result = host.update(data['target'])
    @log.info "Updated #{host::hostname}.#{host::domain} with #{data['target']}"
    return [200, JSON.dump(
      'msg' => 'Successfully updated',
      'target_ip' => result,
      'hostname' => host::hostname, 'domain' => host::domain
    )]
  end
end
