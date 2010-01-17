require 'text'
require 'util'

class Flight < ActiveRecord::Base
	# Status flags used in the database
	STATUS_STARTED=1
	STATUS_LANDED=2
	STATUS_TOWPLANE_LANDED=4

	set_table_name "flug_temp" 

	belongs_to :the_plane   , :class_name => "Plane" , :foreign_key => "flugzeug" 
	belongs_to :the_pilot   , :class_name => "Person", :foreign_key => "pilot"
	belongs_to :the_copilot , :class_name => "Person", :foreign_key => "begleiter"
	belongs_to :the_towplane, :class_name => "Plane" , :foreign_key => "towplane"

	def incomplete_name(last_name, first_name)
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
		return the_pilot.formal_name if the_pilot
		incomplete_name(pnn, pvn)
	end

	def effective_copilot_name
		return the_copilot.formal_name if the_copilot
		incomplete_name(bnn, bvn)
	end

	def effective_towpilot_name
		return the_towpilot.formal_name if the_towpilot
		incomplete_name(tpnn, tpvn)
	end

	def effective_club
		return the_pilot.verein if the_pilot
		return the_plane.verein if the_plane
		nil
	end

	def effective_plane_registration
		return nil if !the_plane
		the_plane.kennzeichen
	end

	def effective_plane_type
		return nil if !the_plane
		the_plane.typ
	end

	def self.mode_text(mode)
		case mode
			when "l"; "Lokal"
			when "k"; "Kommt"
			when "g"; "Geht"
			else; nil
		end
	end

	def mode_text
		Flight.mode_text(modus)
	end

	def mode_text_towflight
		Flight.mode_text(modus_sfz)
	end

	TYPE_NORMAL=2
	TYPE_TRAINING_2=3
	TYPE_TRAINING_1=4
	TYPE_GUEST_PRIVATE=6
	TYPE_GUEST_EXTERNAL=8
	TYPE_TOW=7

	def self.flight_type_text(flight_type)
		case flight_type
			when Flight::TYPE_NORMAL; return "Normalflug"
			when Flight::TYPE_TRAINING_2; return "Schulung (2)"
			when Flight::TYPE_TRAINING_1; return "Schulung (1)"
			when Flight::TYPE_GUEST_PRIVATE; return "Gastflug (P)"
			when Flight::TYPE_GUEST_EXTERNAL; return "Gastflug (E)"
			when Flight::TYPE_TOW; return "Schlepp"
			else; nil
		end
	end

	def is_training?
		self.typ==TYPE_TRAINING_1 || self.typ==TYPE_TRAINING_2
	end

	def is_towflight?
		typ=Flight::TYPE_TOW
	end

	def flight_type_text
		Flight.flight_type_text(typ)
	end

	def is_local?
		modus=="l"
	end

	def starts_here?
		modus=="l" || modus=="g"
	end

	def lands_here?
		modus=="l" || modus=="k"
	end

	def towflight_lands_here?
		modus_sfz=="l" || modus_sfz=="k"
	end

	def started?
		(status & STATUS_STARTED)!=0
	end

	def landed?
		(status & STATUS_LANDED)!=0
	end

	def towflight_landed?
		(status & STATUS_TOWPLANE_LANDED)!=0
	end

	def set_status(started, landed, towflight_landed)
		s=0
		s|=STATUS_STARTED         if started
		s|=STATUS_LANDED          if landed
		s|=STATUS_TOWPLANE_LANDED if towflight_landed
		self.status=s.to_s # the self. is important
	end

	def launch_type
		LaunchType.find(startart)
	end

	def launch_type=(lt)
		if lt
			self.startart=lt.id # self.!
		else
			self.startart=0 # self.!
		end
	end

	def is_airtow?
		return nil if !launch_type
		launch_type.is_airtow?
	end

	def launch_type_text
		return nil if !starts_here?
		return nil if !launch_type
		launch_type.short_name
	end

	def launch_type_pilot_log_designator
		return nil if !starts_here?
		return nil if !launch_type
		launch_type.pilot_log_designator
	end

	def launch_time_valid?
		starts_here? and started?
	end

	def landing_time_valid?
		lands_here? and landed?
	end

	def time_text(time)
		return nil if !time
		time.strftime('%H:%M')
	end

	def effective_launch_time
		return nil if !launch_time_valid?
		startzeit
	end

	def effective_launch_time_text
		time_text(effective_launch_time)
	end

	def effective_landing_time
		return nil if !landing_time_valid?
		landezeit
	end

	def effective_landing_time_text
		time_text(effective_landing_time)
	end

	def duration
		return nil if !starts_here?
		return nil if !lands_here?
		return nil if !started?
		return nil if !landed?
		landezeit-startzeit
	end

	def effective_duration
		return nil if !starts_here?
		return nil if !lands_here?
		return nil if !started?
		return nil if !landed?
		format_duration(landezeit-startzeit, false)
	end

	def effective_towplane_registration
		return nil if !is_airtow?
		# We now know that launch_type is not nil
		return launch_type.registration if launch_type.towplane_known?
		return the_towplane.kennzeichen if the_towplane
	end

	def towplane_id
		lt=launch_type

		return 0 if !lt
		return 0 if !lt.is_airtow?

		if lt.towplane_known?
			# The registration of the towplane is known from the launch type
			plane=Plane.first(:conditions => {:kennzeichen=>lt.registration}, :readonly=>true)
			return 0 if !plane
			plane.id
		else
			# Other towplane - the id of the towplane is stored in the flight
			towplane
		end
	end

	def effective_landing_time_towflight
		return nil if !is_airtow?
		return nil if !towflight_lands_here?
		return nil if !towflight_landed?
		land_schlepp
	end

	def effective_landing_time_text_towflight
		time_text(effective_landing_time_towflight)
	end


	def effective_duration_towflight
		return nil if !is_airtow?
		return nil if !starts_here?
		return nil if !started?
		return nil if !towflight_lands_here?
		return nil if !towflight_landed?
		format_duration(land_schlepp-startzeit, false)
	end

	def effective_destination_towflight
		return nil if !is_airtow?
		zielort_sfz
	end

	def num_people
		if the_copilot
			2
		else
			1
		end
	end

	def effective_time
		if starts_here? && started?
			startzeit
		elsif lands_here? && landed?
			landezeit
		else
			# Prepared flight
			nil
		end
	end

	def effective_date
		time=effective_time
		return nil if !time
		time.date
	end

	def can_merge_plane_log_entry?(prev)
		return false if !prev

		# Cannot merge entries of different planes
		return false unless the_plane.kennzeichen == prev.the_plane.kennzeichen

		# Can only merge if both flights are local, return to the departure
		# airfield and are at the same airfield.
		return false unless (is_local? && prev.is_local?)  # Both flights are local
		return false unless startort == zielort            # This flight is returning
		return false unless prev.startort == prev.zielort  # The previous flight is returning
		return false unless startort == prev.startort      # The flights are at the same airfield
		
		# For motor planes: only allow merging of towflights
		return true if the_plane && (the_plane.glider? || the_plane.motorglider?)
		return true if is_towflight? && prev.is_towflight?

		false
	end

	# additional_conditions is an array ["foo=:f", {:f=>42}]
	def Flight.find_by_date_range(range, options={}, additional_conditions=nil)
		begin_time=range.begin.midnight
		end_time  =range.end  .midnight; end_time=end_time+1.day unless range.exclude_end?

		condition="(startzeit>=:begin_time AND startzeit<:end_time) OR (landezeit>=:begin_time AND landezeit<:end_time)"
		condition_values={ :begin_time=>begin_time, :end_time=>end_time }

		if additional_conditions
			condition="(#{additional_conditions[0]}) AND (#{condition})"
			condition_values.merge! additional_conditions[1]
		end

		query_args=options.merge({ :conditions => [condition, condition_values] })
		# It is possible that the start/landing time of a flight is in range,
		# but insignificant (for example, for a leaving flight). Thus, we have
		# to filter out all flights where the effective date is not in the
		# range.
		Flight.all(query_args).select { |flight| range.include? flight.effective_date }
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
		towflight.flugzeug=towplane_id

		# The pilot of the towflight is the towpilot of the flight; the
		# towflight has not copilot or towpilot
		towflight.pilot=towpilot
		# towflight.copilot
		# towflight.towpilot
		towflight.pvn=tpvn
		towflight.pnn=tpnn
		#towflight.bvn
		#towflight.bnn
		#towflight.tpvn
		#towflight.tpnn
		
		# The launch time of the towflight is the launch time of the flight;
		# the landing time of the towflight is the towflight landing time of
		# the flight
		towflight.startzeit=startzeit
		towflight.landezeit=land_schlepp
		# towflight.land_schlepp

		towflight.launch_type=LaunchType.self_launch
		towflight.typ=TYPE_TOW

		towflight.startort=startort
		towflight.zielort=zielort_sfz
		# towflight.zielort_sfz

		towflight.anzahl_landungen=(towflight_lands_here? && towflight_landed?)?1:0

		towflight.bemerkung="Schleppflug für Flug Nr. #{id}"
		#towflight.abrechnungshinweis
		towflight.modus=modus_sfz
		#towflight.modus_sfz
		#towflight.towplane=nil

		towflight.set_status started?, towflight_landed?, false

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

