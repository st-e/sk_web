# encoding: utf-8

require 'singleton'

class Settings
	include Singleton

	attr_accessor :location
	attr_accessor :local_addresses

	class << self
		attr_accessor :configuration_file
	end
	self.configuration_file=Rails.root.join('config', 'sk_web.yml').to_s

	def initialize
		filename=Settings.configuration_file

		# Require that the file exists, throw an exception if not
		yaml=YAML.load(ERB.new(File.new(filename).read).result)
		config=yaml['config']

		@location        = config['location']        || "???"
		@local_addresses = config['local_addresses'] || []
	end

	# address is an array of 4 strings
	def address_matches(spec, address)
		(0..3).all? { |i| spec[i]=='*' || spec[i]==address[i] }
	end

	# address is a string
	def address_is_local?(address)
		@local_addresses.any? { |spec| address_matches spec.strip.split('.'), address.strip.split('.') }
	end
end

