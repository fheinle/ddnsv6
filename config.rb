require 'yaml'

class Config
  attr_reader :config

  def initialize
    @config = YAML.load_file(
      File.join(
        File.dirname(__FILE__),
        'ddnsv6.conf.yaml'
      )
    )
    if File.exist? 'whitelist.txt'
      host_whitelist = File.open('whitelist.txt').read.lines.map(&:chomp).map(&:strip)
      @config['whitelist'] = host_whitelist
    end
  end

  def save
    File.open('ddnsv6.conf.yaml') do |config_file|
      config_file.write(YAML.dump(@config))
    end
  end

  # update timestamp of last DNS upload
  def update_timestamp
    @config['timestamp'] = Time.now
    self.save
  end
end