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
			plane  =flight.the_plane
			pilot  =flight.the_pilot
			copilot=flight.the_copilot

			pilot_last_name  =(pilot)?(pilot.nachname  ):flight.pnn
			pilot_first_name =(pilot)?(pilot.vorname   ):flight.pvn
			pilot_code       =(pilot)?(pilot.vereins_id):nil
			pilot_club       =(pilot)?(pilot.verein    ):nil
			copilot_last_name  =(copilot)?(copilot.nachname  ):flight.bnn
			copilot_first_name =(copilot)?(copilot.vorname   ):flight.bvn
			copilot_code       =(copilot)?(copilot.vereins_id):nil

			training=flight.is_training?

			if (training)
				# Student is stored pilot, instructor as copilot
				student_last_name, student_first_name, student_code, student_club=
				 [pilot_last_name,   pilot_first_name,   pilot_code,   pilot_club]

				instructor_last_name, instructor_first_name, instructor_code=
				  [copilot_last_name,    copilot_first_name,    copilot_code]
			end

			launch_type=(flight.starts_here?)?(flight.launch_type):nil
			if launch_type
				launch_type_text=case launch_type.type
					when 'airtow': 'FS'
					when 'self'  : 'SS'
					when 'winch' : launch_type.short_name
					when 'other' : 'SO'
					else           'SO'
				end
			else
				launch_type_text="???"
			end

			flight_type_text=
				case flight.abrechnungshinweis
				when /Bezahlt/i       : "B"
				when /Werkstattflug/i : "W"
				when /Pauschal/i      : "P"
				when /Kinderfliegen/i : "K"
				else \
					case flight.typ
					when Flight::TYPE_NORMAL         : 'Ü'
					when Flight::TYPE_TRAINING_2     : 'S'
					when Flight::TYPE_TRAINING_1     : 'E'
					when Flight::TYPE_GUEST_PRIVATE  : 'Ü'
					when Flight::TYPE_GUEST_EXTERNAL : 'Ü'
					when Flight::TYPE_TOW            : '-'
					else                       ''
					end
				end

			date=flight.effective_date

			[
				(date)?(date.strftime('%Y%m%d')):"",
				(flight.launch_time_valid?)?(flight.startzeit.hour):"",
				(flight.launch_time_valid?)?(flight.startzeit.min):"",
				(flight.landing_time_valid?)?(flight.landezeit.hour):"",
				(flight.landing_time_valid?)?(flight.landezeit.min):"",
				(plane)?(plane.kennzeichen):nil,
				(plane)?(plane.verein):nil,
				flight_type_text,
				launch_type_text,
				(training)?(instructor_last_name ):(pilot_last_name   ),
				(training)?(instructor_first_name):(pilot_first_name  ),
				(training)?(student_code         ):(pilot_code        ),
				(training)?(student_club         ):(pilot_club        ),
				(training)?(student_last_name    ):(copilot_last_name ),
				(training)?(student_first_name   ):(copilot_first_name),
				(training)?(instructor_code      ):(copilot_code      ),
				flight.bemerkung,
				flight.abrechnungshinweis,
				flight.id
			].map { |value| value || "" }
		}
	end
end

