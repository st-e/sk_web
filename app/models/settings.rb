require 'fileutils'

# TODO should not be a model, move to lib
class Settings
	include Singleton

	# TODO: this should be done in environment.rb, where all of the other
	# SK_WEB_X environment variables are read
	Filename=Rails.root.join('config', 'sk_web.yml').to_s unless ENV['SK_WEB_ETC']
	Filename=File.join(ENV['SK_WEB_ETC'], 'sk_web.yml')   if     ENV['SK_WEB_ETC']
	DistFilename=Filename+".dist"

	attr_accessor :location
	attr_accessor :local_addresses

	def initialize
		# This should probably be done in environment.rb, along with Database.yml
		if (!File.exist?(Filename) && File.exist?(DistFilename))
			FileUtils.cp DistFilename, Filename
		end

		if (File.exist? Filename)
			yaml=YAML.load(ERB.new(File.new(Filename).read).result)
			config=yaml['config']

			@location        = config['location']
			@local_addresses = config['local_addresses']
		end

		@location        ||= "???"
		@local_addresses ||= []
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

