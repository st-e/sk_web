# Load information from config files
# encoding: utf-8
# This replaces the old lib/settings.rb
# Author Claas Koehler
# Date 2016-03-31
# config/initializers/load_config.rb

#read config file
yaml= YAML.load_file("#{Rails.root}/config/sk_web.yml")
cfg= yaml['config']

#set config variables
SkWeb::Application.config.location       = cfg['location']        || "???" 
SkWeb::Application.config.local_addresses= cfg['local_addresses'] || [] 
#require 'singleton'

#class Settings
#    include Singleton

#    attr_accessor :location
#    attr_accessor :local_addresses

#    class << self
#        attr_accessor :configuration_file
#    end
#    self.configuration_file=Rails.root.join('config', 'sk_web.yml').to_s

#    def initialize
#        filename=Settings.configuration_file

        # Require that the file exists, throw an exception if not
#        yaml=YAML.load(ERB.new(File.new(filename).read).result)
#        config=yaml['config']
 #       $stderr.puts %(Read config)

#        @location        = config['location']        || "???"
#        @local_addresses = config['local_addresses'] || []
#    end

#    # address is an array of 4 strings
#    def address_matches(spec, address)
#        (0..3).all? { |i| spec[i]=='*' || spec[i]==address[i] }
#    end

    # address is a string
#    def address_is_local?(address)
#        @local_addresses.any? { |spec| address_matches spec.strip.split('.'), address.strip.split('.') }
#    end
#end

#$stderr.puts %(Before config)
#debug
#$stderr.puts %("Location: '#{Settings.instance.location}'")