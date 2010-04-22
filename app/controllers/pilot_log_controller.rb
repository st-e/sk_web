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

		condition=case params['flight_instructor_mode']
			when 'strict' then
				"pilot_id=:person OR (copilot_id=:person AND type=:type)"
			when 'loose' then
				"pilot_id=:person OR copilot_id=:person"
			else
				"pilot_id=:person"
		end
		condition_values={:person=>@person.id, :type=>Flight::TYPE_TRAINING_2}

		@flights=Flight.find_by_date_range(@date_range, {:readonly=>true}, [condition, condition_values]).sort_by { |flight| flight.effective_time }

		if params['gliders_only']
			# Reject all flights where the plane (exist and) is not a glider
			@flights.reject! { |flight|
				flight.plane && !flight.plane.glider?
			}
		end

		format=params['format'] || @default_format

		@table=make_table(@flights)

		respond_to do |format|
			format.html { render 'pilot_log'           ; set_filename "flugbuch_#{date_range_filename(@date_range)}.html" }
			format.pdf  { @faux_template='pilot_log';
				          render 'layouts/faux_layout' ; set_filename "flugbuch_#{date_range_filename(@date_range)}.pdf"  }
			format.csv  { render 'pilot_log'           ; set_filename "flugbuch_#{date_range_filename(@date_range)}.csv"  }
			#format.pdf  { render_pdf_latex 'pilot_log.tex'; set_filename "flugbuch_#{date_range_filename(@date_range)}.pdf"  }
			#format.tex  { render 'pilot_log'        ; set_filename "flugbuch_#{date_range_filename(@date_range)}.tex"  }
			#format.xml  { render :xml => @flights   ; set_filename "flugbuch_#{date_range_filename(@date_range)}.xml"  }
			#format.json { render :json => @flights  ; set_filename "flugbuch_#{date_range_filename(@date_range)}.json" }
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

