# encoding: utf-8

class PilotLogController < ApplicationController
	require_login :index, :show

	def initialize
		@default_format="html"
		@default_flight_instructor_mode="no"
	end

	def index
		user=current_user
		@person=user.person

		if !@person
			flash[:error]="Es kann kein Flugbuch angezeigt werden, da dem Benutzer #{user.username} keine Person zugeordnet ist."
			redirect_to :back
			return
		end

		@format=params['format'] || @default_format
		@formats=formats
		@flight_instructor_mode=params['flight_instructor_mode'] unless params['flight_instructor_mode']==@default_flight_instructor_mode
		@gliders_only          =params['gliders_only'          ]
		redirect_to_with_date :action=>'show', :format=>@format, :flight_instructor_mode=>@flight_instructor_mode, :gliders_only=>@gliders_only
	end

	def show
		user=current_user
		@person=user.person

		if !@person
			flash[:error]="Es kann kein Flugbuch angezeigt werden, da dem Benutzer #{user.username} keine Person zugeordnet ist."
			redirect_to :back
			return
		end

		@date_range=date_range(params['date'])

		# Get all flights where the person was involved, either as pilot,
		# copilot or towpilot
		condition="pilot_id=:person OR copilot_id=:person OR towpilot_id=:person"
		condition_values={:person=>@person.id}
		@flights=Flight.find_by_date_range(@date_range, {:readonly=>true}, [condition, condition_values]).sort_by { |flight| flight.effective_time }

		if params['gliders_only']
			# Reject all flights where the plane (exist and) is not a glider
			@flights.reject! { |flight|
				flight.plane && !flight.plane.glider?
			}
		else
			# Add the towflights (towflights are never glider flights)
			@flights+=Flight.make_towflights(@flights)
		end

		# Select only those flights where the person is the pilot or, according
		# to the flight instructor mode, the copilot.
		# The towflights have been added to the list with the pilot the person. 
		@flights=@flights.select { |flight|
			if flight.pilot_id==@person.id
				# Person is pilot
				true
			elsif flight.copilot_id==@person.id
				# Person is copilot
				case params['flight_instructor_mode']
				when 'strict' then
					# Include flights as copilot if the type is training
					flight.type==Flight::TYPE_TRAINING_2
				when 'loose' then
					# Include flights as copilot
					true
				else
					# Don't include flights as copilot
					false
				end
			else
				# Person is neither pilot nor copilot
				false
			end
		}

		@table=make_table(@flights)

		respond_to do |format|
			filename_base="flugbuch_#{date_range_filename(@date_range)}"

			format.html {                             render 'pilot_log'           ; set_filename "#{filename_base}.html" }
			format.pdf  { @faux_template='pilot_log'; render 'layouts/faux_layout' ; set_filename "#{filename_base}.pdf"  }
			format.csv  {                             render 'pilot_log'           ; set_filename "#{filename_base}.csv"  }
		end
	end

protected
	def formats
		[
			['HTML' , 'html' ],
			['CSV'  , 'csv'  ],
			['PDF'  , 'pdf'  ]
			#['LaTeX', 'latex']
		]
	end

	def make_table(flights, short=false)
		columns = [
			{ :title => 'Datum'           , :width => 16 },
			{ :title => 'Muster'          , :width => 12 },
			{ :title => 'Kennzeichen'     , :width => 18 },
			{ :title => 'Pilot'           , :width => 20 },
			{ :title => 'Begleiter'       , :width => 20 },
			{ :title => 'Startart'        , :width => 11 },
			{ :title => 'Starort'         , :width => 15 },
			{ :title => 'Zielort'         , :width => 15 },
			{ :title => 'Start'           , :width => 12 },
			{ :title => 'Landung'         , :width => 12 },
			{ :title => 'Dauer'           , :width => 12 },
			{ :title => 'Bemerkungen'     , :width => 20, :stretch=>1 }
		]

		rows=flights.each_with_index.map { |flight, index|
			comments=[]
			comments << "#{flight.effective_towplane_registration} #{flight.effective_duration_towflight}" if flight.is_airtow?
			comments << flight.comments if !flight.comments.blank?
		
			[
			date_formatter(german_format, true).call(flight.effective_date),
			flight.plane.type                               ,
			flight.plane.registration                       ,
			flight.effective_pilot_name               || "?",
			flight.effective_copilot_name                   ,
			flight.launch_method_log_string           || "?",
			flight.departure_location                       ,
			flight.landing_location                         ,
			flight.effective_departure_time_text      || "?",
			flight.effective_landing_time_text        || "?",
			flight.effective_duration                 || "?",
			comments.join('; ')
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

