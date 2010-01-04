require 'text'
require 'util'

class Flight < ActiveRecord::Base
	# Status flags used in the database
	STATUS_STARTED=1
	STATUS_LANDED=2
	STATUS_TOWPLANE_LANDED=4

	set_table_name "flug_temp" 

	belongs_to :the_plane  , :class_name => "Plane" , :foreign_key => "flugzeug" 
	belongs_to :the_pilot  , :class_name => "Person", :foreign_key => "pilot"
	belongs_to :the_copilot, :class_name => "Person", :foreign_key => "begleiter"
	# TODO towplane, towpilot

	def effective_pilot_name
		# TODO handle incomplete names
		return the_pilot.formal_name if the_pilot
		nil
	end

	def effective_copilot_name
		# TODO handle incomplete names
		return the_copilot.formal_name if the_copilot
		nil
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

	def self.flight_type_text(flight_type)
		case flight_type
			when 1; return nil
			when 2; return "Normalflug"
			when 3; return "Schulung (2)"
			when 4; return "Schulung (1)"
			when 5; nil
			when 6; return "Gastflug (P)"
			when 8; return "Gastflug (E)"
			when 7; return "Schlepp"
			else; nil
		end
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
		status & STATUS_STARTED
	end

	def landed?
		status & STATUS_LANDED
	end

	def towflight_landed?
		status & STATUS_TOWPLANE_LANDED
	end

	def launch_type
		LaunchType.find(startart)
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

	def effective_launch_time
		return nil if !starts_here?
		return nil if !started?
		startzeit.strftime('%H:%M')
	end

	def effective_landing_time
		return nil if !lands_here?
		return nil if !landed?
		landezeit.strftime('%H:%M')
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
		launch_type.registration
		# TODO other airtow!
	end

	def effective_landing_time_towflight
		return nil if !is_airtow?
		return nil if !towflight_lands_here?
		return nil if !towflight_landed?
		land_schlepp.strftime('%H:%M')
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
		if copilot
			2
		else
			1
		end
	end

	def effective_time
		if starts_here?
			startzeit
		elsif lands_here?
			landezeit
		else
			# This should not happen because any flight either starts or lands here
			nil
		end
	end

	# TODO use instead of effective_time.date
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
		# TODO: gliders and motor gliders true, other only for towflights
		true
	end
end

