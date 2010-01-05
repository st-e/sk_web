class LaunchType
	attr_reader :id, :type, :registration, :name, :short_name, :keyboard_shortcut, :pilot_log_designator, :person_required

	def initialize(id, type, registration, name, short_name, keyboard_shortcut, pilot_log_designator, person_required)
		@id=id
		@type=type
		@registration=registration
		@name=name
		@short_name=short_name
		@keyboard_shortcut=keyboard_shortcut
		@pilot_log_designator=pilot_log_designator
		@person_required=person_required
	end

	def to_s
		"#{@id}: #{keyboard_shortcut} - #{name} (#{short_name}/#{pilot_log_designator})"
	end

	def is_airtow?
		@type=='airtow'
	end

	def towplane_known?
		!@registration.blank?
	end

	def LaunchType.all
		Settings.instance.launch_types.dup
	end

	def LaunchType.find(id)
		Settings.instance.launch_types.find { |launch_type| launch_type.id==id }
	end

	def LaunchType.self_launch
		puts Settings.instance.launch_types.map { |lt| lt.inspect }
		Settings.instance.launch_types.find { |launch_type| launch_type.type=='self' }
	end
end


