require 'text'

class Flight < ActiveRecord::Base
	# Status flags used in the database
	STATUS_STARTED=1
	STATUS_LANDED=2
	STATUS_TOWPLANE_LANDED=4

	set_table_name "flug_temp" 

	belongs_to :plane,  :foreign_key => "flugzeug" 
	belongs_to :pilot, :class_name => "Person", :foreign_key => "pilot"
	belongs_to :copilot, :class_name => "Person", :foreign_key => "begleiter"

	def effective_pilot_name
		return pilot.formal_name if pilot
		nil
	end

	def effective_copilot_name
		return copilot.formal_name if copilot
		nil
	end

	def effective_club
		return pilot.verein if pilot
		return plane.verein if plane
		nil
	end

	def effective_plane_registration
		return nil if !plane
		plane.kennzeichen
	end

	def effective_plane_type
		return nil if !plane
		plane.typ
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
		end
	end

	def can_merge_plane_log_entry?(prev)
		return false if !prev

		# Cannot merge entries of different planes
		return false unless plane.kennzeichen == prev.plane.kennzeichen

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

