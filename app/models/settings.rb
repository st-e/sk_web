require 'text'

class Settings
	include Singleton

	class ConfigFileNotFound <Exception
	end

	attr_reader :location, :launch_types

	def config_filename
		[
			"#{RAILS_ROOT}/config/startkladde.conf",
			"#{ENV['HOME']}/.startkladde.conf"
		].find { |file| File.exist? file }
	end
			

	def initialize
		@location="???"
		@launch_types=[]
		@local_addresses=[]

		filename=config_filename
		raise Settings::ConfigFileNotFound if filename.nil?

		puts "Reading configuration from #{filename}"
		File.new(filename).each_line { |line|
			line.strip!

			if !(line =~ /^#/) && !line.blank?
				if (line =~ /^startart (.*), (.*), (.*), (.*), (.*), (.*), (.*), (.*)/i)
					id                   =$1.strip.to_i
					type                 =$2.strip
					registration         =$3.strip # winch, airtow, self, other
					name                 =$4.strip
					short_name           =$5.strip
					keyboard_shortcut    =$6.strip
					pilot_log_designator =$7.strip
					person_required      =$8.strip.to_b

					launch_type=LaunchType.new(id, type, registration, name, short_name, keyboard_shortcut, pilot_log_designator, person_required)
					@launch_types << launch_type
				elsif (line =~ /ort (.*)/i)
					@location=$1.strip
				elsif (line =~ /local_hosts (.*)/i)
					@local_addresses=$1.split(',').map { |address| address.strip.split('.') }
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

