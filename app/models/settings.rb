class Settings
	include Singleton

	class ConfigFileNotFound <Exception
	end

	attr_reader :location

	def config_filename
		[
			"#{RAILS_ROOT}/config/startkladde.conf",
			"#{ENV['HOME']}/.startkladde.conf"
		].find { |file| File.exist? file }
	end
			

	def initialize
		@location="???"
		@local_addresses=[]

		filename=config_filename
		raise Settings::ConfigFileNotFound if filename.nil?

		puts "Reading configuration from #{filename}"
		File.new(filename).each_line { |line|
			line.strip!

			if !(line =~ /^#/) && !line.blank?
				if (line =~ /ort (.*)/i)
					@location=$1.strip
				elsif (line =~ /local_hosts (.*)/i)
					@local_addresses+=$1.split(',').map { |address| address.strip.split('.') }
				end
			end
		}
	end

	# address is an array of 4 strings
	def address_matches(spec, address)
		(0..3).all? { |i| spec[i]=='*' || spec[i]==address[i] }
	end

	# address is a string
	def address_is_local?(address)
		@local_addresses.any? { |spec| address_matches spec, address.strip.split('.') }
	end
end

