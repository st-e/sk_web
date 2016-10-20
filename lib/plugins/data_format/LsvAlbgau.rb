# encoding: utf-8

DataFormatPlugin.define "lsv_albgau" do
	title "LSV Albgau"
	author "Martin Herrmann"
	version "1.0"

	def column_titles
		[
			"Datum",
			"Startzeit Stunden",
			"Startzeit Minuten",
			"Landezeit Stunden",
			"Landezeit Minuten",
			"Flugzeug Kennzeichen",
			"Flugzeug Verein",
			"Flugart",
			"Startart",
			"Pilot Nachname",
			"Pilot Vorname",
			"Pilot Code",
			"Pilot Verein",
			"Begleiter Nachname",
			"Begleiter Vorname",
			"Begleiter Code",
			"Bemerkungen",
			"Abrechnungshinweis",
			"ID"
		]
	end

	# Spezifikation:
	# Schulung:
	#   - Lehrer Nachname
	#   - Lehrer Vorname
	#   - Schüler Code
	#   - Schüler Verein
	#   - Schüler Nachname
	#   - Schüler Vorname
	#   - Lehrer Code
	# Sonstige:
	#   - Pilot Nachname
	#   - Pilot Vornamen
	#   - Pilot Code
	#   - Pilot Verein
	#   - Begleiter Nachname
	#   - Begleiter Vorname
	#   - Begleiter Code


	def column_values(flights)
		flights.map { |flight|
			plane  =flight.plane
			pilot  =flight.pilot
			copilot=flight.copilot

			pilot_last_name  =(pilot)?(pilot.last_name ):flight.pilot_last_name
			pilot_first_name =(pilot)?(pilot.first_name):flight.pilot_first_name
			pilot_code       =(pilot)?(pilot.club_id   ):nil
			pilot_club       =(pilot)?(pilot.club      ):nil
			copilot_last_name  =(copilot)?(copilot.last_name  ):flight.copilot_last_name
			copilot_first_name =(copilot)?(copilot.first_name ):flight.copilot_first_name
			copilot_code       =(copilot)?(copilot.club_id    ):nil

			training=flight.is_training?

			if (training)
				# Student is stored pilot, instructor as copilot
				student_last_name, student_first_name, student_code, student_club=
				 [pilot_last_name,   pilot_first_name,   pilot_code,   pilot_club]

				instructor_last_name, instructor_first_name, instructor_code=
				  [copilot_last_name,    copilot_first_name,    copilot_code]
			end

			launch_method=(flight.departs_here?)?(flight.launch_method):nil
			if launch_method
				launch_method_text=case launch_method.type
					when 'airtow' then 'FS'
					when 'self'   then 'SS'
					when 'winch'  then launch_method.short_name
					when 'other'  then 'SO'
					else           'SO'
				end
			else
				launch_method_text="???"
			end

			flight_type_text=
				case flight.accounting_notes
				when /Bezahlt/i       then "B"
				when /Werkstattflug/i then "W"
				when /Pauschal/i      then "P"
				when /Kinderfliegen/i then "K"
				else \
					case flight.type
					when Flight::TYPE_NORMAL         then 'Ü'
					when Flight::TYPE_TRAINING_2     then 'S'
					when Flight::TYPE_TRAINING_1     then 'E'
					when Flight::TYPE_GUEST_PRIVATE  then 'Ü'
					when Flight::TYPE_GUEST_EXTERNAL then 'Ü'
					when Flight::TYPE_TOW            then '-'
					else                       ''
					end
				end

			date=flight.effective_date

			departure_time=flight.effective_departure_time
			landing_time=flight.effective_landing_time

			[
				(date)?(date.strftime('%Y%m%d')):"",
				(departure_time)?(departure_time.hour):"",
				(departure_time)?(departure_time.min):"",
				(landing_time)?(landing_time.hour):"",
				(landing_time)?(landing_time.min):"",
				(plane)?(plane.registration):nil,
				(plane)?(plane.club):nil,
				flight_type_text,
				launch_method_text,
				(training)?(instructor_last_name ):(pilot_last_name   ),
				(training)?(instructor_first_name):(pilot_first_name  ),
				(training)?(student_code         ):(pilot_code        ),
				(training)?(student_club         ):(pilot_club        ),
				(training)?(student_last_name    ):(copilot_last_name ),
				(training)?(student_first_name   ):(copilot_first_name),
				(training)?(instructor_code      ):(copilot_code      ),
				flight.comments,
				flight.accounting_notes,
				flight.id
			].map { |value| value || "" }
		}
	end
end

