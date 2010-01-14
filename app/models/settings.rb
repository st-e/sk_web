require 'text'

class Settings
	include Singleton
	
	attr_reader :location, :launch_types

	def local_config_filename
		"#{RAILS_ROOT}/config/startkladde.conf"
	end

	def home_config_filename
		"#{ENV['HOME']}/.startkladde.conf"
	end

	def config_filename
		return home_config_filename if File.exist? home_config_filename
		return local_config_filename if File.exist? local_config_filename
		nil
	end

	def initialize
		@location="???"
		@launch_types=[]

		puts "Reading configuration from #{config_filename}"
		File.new(config_filename).each_line { |line|
			line.strip!

			if !(line =~ /^#/) && !line.blank?
				if (line =~ /^startart (.*), (.*), (.*), (.*), (.*), (.*), (.*), (.*)/)
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
					#puts launch_type
				elsif (line =~ /ort (.*)/)
					@location=$1.strip
				end
			end
		}
	end
end
