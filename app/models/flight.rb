# encoding: utf-8

require_dependency 'duration'

class Flight < ActiveRecord::Base
	belongs_to :plane
	belongs_to :towplane, :class_name => "Plane"

	belongs_to :pilot   , :class_name => "Person"
	belongs_to :copilot , :class_name => "Person"
	belongs_to :towpilot, :class_name => "Person"

	belongs_to :launch_method

	# Rails sez:
	# The single-table inheritance mechanism failed to locate the subclass:
	# 'normal'. This error is raised because the column 'type' is reserved for
	# storing the class in case of inheritance. Please rename this column if
	# you didn't intend it to be used for storing the inheritance class or
	# overwrite Flight.inheritance_column to use another column for that
	# information.
	def Flight.inheritance_column
		"class_type"
	end

	# Hack to allow a type column
	def type
		attributes['type']
	end


	def incomplete_formal_name(last_name, first_name)
		if last_name.blank? && first_name.blank?
			# Both blank
			nil
		elsif last_name.blank?
			"(?, #{first_name})"
		elsif first_name.blank?
			"(#{last_name}, ?)"
		else
			"(#{last_name}, #{first_name})"
		end
	end

	def effective_pilot_name
		return pilot.formal_name if pilot
		incomplete_formal_name(pilot_last_name, pilot_first_name)
	end

	def effective_copilot_name
		return copilot.formal_name if copilot
		incomplete_formal_name(copilot_last_name, copilot_first_name)
	end

	def effective_towpilot_name
		return towpilot.formal_name if towpilot
		incomplete_formal_name(towpilot_last_name, towpilot_first_name)
	end

	def effective_club
		return pilot.club if pilot
		return plane.club if plane
		nil
	end

	def effective_plane_registration
		return nil if !plane
		plane.registration
	end

	def effective_plane_type
		return nil if !plane
		plane.type
	end

	def effective_mode
		mode || "local"
	end

	def self.mode_text(mode)
		case mode
			when "local"  ; "Lokal"
			when "coming" ; "Kommt"
			when "leaving"; "Geht"
			else; nil
		end
	end

	def mode_text
		Flight.mode_text(effective_mode)
	end

	def mode_text_towflight
		Flight.mode_text(towflight_mode)
	end

	TYPE_NORMAL        ='normal'
	TYPE_TRAINING_2    ='training_2'
	TYPE_TRAINING_1    ='training_1'
	TYPE_GUEST_PRIVATE ='guest_private'
	TYPE_GUEST_EXTERNAL='guest_external'
	TYPE_TOW           ='tow'

	def self.flight_type_text(flight_type)
		case flight_type
			when Flight::TYPE_NORMAL        ; return "Normalflug"
			when Flight::TYPE_TRAINING_2    ; return "Schulung (2)"
			when Flight::TYPE_TRAINING_1    ; return "Schulung (1)"
			when Flight::TYPE_GUEST_PRIVATE ; return "Gastflug (P)"
			when Flight::TYPE_GUEST_EXTERNAL; return "Gastflug (E)"
			when Flight::TYPE_TOW           ; return "Schlepp"
			else; nil
		end
	end

	def is_training?
		self.type==TYPE_TRAINING_1 || self.type==TYPE_TRAINING_2
	end

	def is_towflight?
		type=Flight::TYPE_TOW
	end

	def flight_type_text
		Flight.flight_type_text(type)
	end

	def is_local?
		effective_mode=="local"
	end

	def departs_here?
		effective_mode=="local" || effective_mode=="leaving"
	end

	def lands_here?
		effective_mode=="local" || effective_mode=="coming"
	end

	def towflight_lands_here?
		towflight_mode=="local" || towflight_mode=="coming"
	end

	def departed?
		self.departed
	end

	def landed?
		self.landed
	end

	def towflight_landed?
		self.towflight_landed
	end

	def is_airtow?
		return nil if !departs_here?
		return nil if !launch_method
		launch_method.is_airtow?
	end

	def launch_method_text
		return nil if !departs_here?
		return nil if !launch_method
		launch_method.short_name
	end

	def launch_method_log_string
		return nil if !departs_here?
		return nil if !launch_method
		launch_method.log_string
	end

	def departure_time_valid?
		departs_here? and departed?
	end

	def landing_time_valid?
		lands_here? and landed?
	end

	def time_text(time)
		return nil if !time
		time.strftime('%H:%M')
	end

	def effective_departure_time
		return nil if !departure_time_valid?
		departure_time
	end

	def effective_departure_time_text
		time_text(effective_departure_time)
	end

	def effective_landing_time
		return nil if !landing_time_valid?
		landing_time
	end

	def effective_landing_time_text
		time_text(effective_landing_time)
	end

	def duration
		return nil if !departs_here?
		return nil if !lands_here?
		return nil if !departed?
		return nil if !landed?
		landing_time-departure_time
	end

	def effective_duration
		return nil if !departs_here?
		return nil if !lands_here?
		return nil if !departed?
		return nil if !landed?
		format_duration(landing_time-departure_time, false)
	end

	def effective_towplane_registration
		return nil if !is_airtow?
		# We now know that launch_method is not nil
		return launch_method.towplane_registration if launch_method.towplane_known?
		return towplane.registration if towplane
	end

	def effective_towplane_id
		lm=launch_method

		return 0 if !lm
		return 0 if !lm.is_airtow?

		if lm.towplane_known?
			# The registration of the towplane is known from the launch method
			plane=Plane.first(:conditions => {:registration=>lm.towplane_registration}, :readonly=>true)
			return 0 if !plane
			plane.id
		else
			# Other towplane - the id of the towplane is stored in the flight
			towplane_id
		end
	end

	def effective_landing_time_towflight
		return nil if !is_airtow?
		return nil if !towflight_lands_here?
		return nil if !towflight_landed?
		towflight_landing_time
	end

	def effective_landing_time_text_towflight
		time_text(effective_landing_time_towflight)
	end


	def effective_duration_towflight
		return nil if !is_airtow?
		return nil if !departs_here?
		return nil if !departed?
		return nil if !towflight_lands_here?
		return nil if !towflight_landed?
		format_duration(towflight_landing_time-departure_time, false)
	end

	def effective_destination_towflight
		return nil if !is_airtow?
		towflight_landing_location
	end

	def num_people
		if copilot
			2
		else
			1
		end
	end

	def effective_time
		if departs_here? && departed?
			departure_time
		elsif lands_here? && landed?
			landing_time
		else
			# Prepared flight
			nil
		end
	end

	# Note that this method is relatively slow
	def effective_date
		time=effective_time
		return nil if !time
		time.date
	end

	def can_merge_plane_log_entry?(prev)
		return false if !prev

		# Cannot merge entries of different planes
		return false unless plane.registration == prev.plane.registration

		# Can only merge if both flights are local, return to the departure
		# airfield and are at the same airfield.
		return false unless (is_local?          and prev.is_local?         ) # Both flights are local
		return false unless (departure_location and prev.departure_location) # Both flights have a departure location
		return false unless (landing_location   and prev.landing_location  ) # Both flights have a landing location
		return false unless      departure_location.strip.downcase ==        landing_location.strip.downcase  # This flight is returning
		return false unless prev.departure_location.strip.downcase ==   prev.landing_location.strip.downcase  # The previous flight is returning
		return false unless      departure_location.strip.downcase == prev.departure_location.strip.downcase  # The flights are at the same airfield
		
		# For motor planes: only allow merging of towflights
		return true if plane && (plane.glider? || plane.motorglider?)
		return true if is_towflight? && prev.is_towflight?

		false
	end

	# additional_conditions is an array ["foo=:f", {:f=>42}]
	def Flight.find_by_date_range(range, options={}, additional_conditions=nil)
		begin_time=range.begin.midnight
		end_time  =range.end  .midnight; end_time=end_time+1.day unless range.exclude_end?

		# Note that the departure/landing time of a flight may be in range but
		# insignificant (for example, if the flight does not depart here).
		condition="(departure_time>=:begin_time AND departure_time<:end_time AND (mode='local' OR mode='leaving') AND departed) OR (landing_time>=:begin_time AND landing_time<:end_time AND (mode='local' OR mode='coming') AND landed)"
		condition_values={ :begin_time=>begin_time, :end_time=>end_time }

		if additional_conditions
			condition="(#{additional_conditions[0]}) AND (#{condition})"
			condition_values.merge! additional_conditions[1]
		end

		query_args=options.merge({ :conditions => [condition, condition_values] })
		Flight.all(query_args)
	end

	def make_towflight
		towflight=Flight.new

		# Make sure the towflight is not accidentally saved
		class << towflight
			def create_or_update; raise ArgumentError, "Thou shalt not save this flight!"; end
			def save;             raise ArgumentError, "Thou shalt not save this flight!"; end
			def save!;            raise ArgumentError, "Thou shalt not save this flight!"; end
		end

		# The tow flight has the same ID as the flight so they can be related
		# to each other
		towflight.id=id

		# The plane of the towflight is the towplane of the flight
		towflight.plane_id=effective_towplane_id

		# The pilot of the towflight is the towpilot of the flight; the
		# towflight has not copilot or towpilot
		towflight.pilot_id=towpilot_id
		# towflight.copilot
		# towflight.towpilot
		towflight.pilot_first_name=towpilot_first_name
		towflight.pilot_last_name=towpilot_last_name
		#towflight.copilot_first_name
		#towflight.copilot_last_name
		#towflight.towpilot_first_name
		#towflight.towpilot_last_name
		
		# The departure time of the towflight is the departure time of the flight;
		# the landing time of the towflight is the towflight landing time of
		# the flight
		towflight.departure_time=departure_time
		towflight.landing_time=towflight_landing_time
		# towflight.towflight_landing_time

		towflight.launch_method=LaunchMethod.self_launch
		towflight.type=TYPE_TOW

		towflight.departure_location=departure_location
		towflight.landing_location=towflight_landing_location
		# towflight.towflight_landing_location

		towflight.num_landings=(towflight_lands_here? && towflight_landed?)?1:0

		towflight.comments="Schleppflug für Flug Nr. #{id}"
		#towflight.accounting_notes
		towflight.mode=towflight_mode
		#towflight.towflight_mode
		#towflight.towplane_id=nil

		towflight.departed         = departed
		towflight.landed           = towflight_landed
		towflight.towflight_landed = false

		towflight
	end

	def self.make_towflights(flights)
		towflights=[]

		flights.each { |flight|
			if flight.is_airtow?
				towflight=flight.make_towflight
				towflights << towflight if towflight
			end
		}

		towflights
	end
end

