require 'date'
require 'tmpdir'

class PilotLogController < ApplicationController
	def initialize
		@default_format="html"
		@default_flight_instructor_mode="no"
	end

	def index
		# TODO make function
		user=User.find(session[:username])
		@person=user.associated_person

		if !@person
			flash[:error]="Es kann kein Flugubch angezeigt werden, da dem Benutzer #{user.username} keine Person zugeordnet ist."
			redirect_to :back # TODO or default
			return
		end

		@format=params['format'] || @default_format
		@flight_instructor_mode=params['flight_instructor_mode'] unless params['flight_instructor_mode']==@default_flight_instructor_mode
		redirect_to_with_date :action=>'show', :format=>@format, :flight_instructor_mode=>@flight_instructor_mode
	end

	def show
		# TODO make function
		user=User.find(session[:username])

		@person=user.associated_person

		if !@person
			flash[:error]="Es kann kein Flugubch angezeigt werden, da dem Benutzer #{user.username} keine Person zugeordnet ist."
			redirect_to :back # TODO or default
			return
		end

		@date_range=date_range(params['date'])

		condition=case params['flight_instructor_mode']
			when 'strict' then
				"pilot=:person OR (begleiter=:person AND typ=:type)"
			when 'loose' then
				"pilot=:person OR begleiter=:person"
			else
				"pilot=:person"
		end
		condition_values={:person=>@person.id, :type=>Flight.flight_type_training2}

		# TODO have to sort?
		@flights=Flight.find_by_date_range(@date_range, {:readonly=>true}, [condition, condition_values])#.sort_by { |flight| flight.effective_time }



		format=params['format'] || @default_format

		@table=make_table(@flights)

		respond_to do |format|
			format.html { render 'pilot_log'        ; set_filename "flugbuch_#{date_range_filename(@date_range)}.html" }
			format.pdf  { render_pdf 'pilot_log.tex'; set_filename "flugbuch_#{date_range_filename(@date_range)}.pdf"  }
			format.tex  { render 'pilot_log'        ; set_filename "flugbuch_#{date_range_filename(@date_range)}.tex"  }
			format.csv  { render 'pilot_log'        ; set_filename "flugbuch_#{date_range_filename(@date_range)}.csv"  }
			#format.xml  { render :xml => @flights   ; set_filename "flugbuch_#{date_range_filename(@date_range)}.xml"  }
			#format.json { render :json => @flights  ; set_filename "flugbuch_#{date_range_filename(@date_range)}.json" }
		end
	end

protected
	def make_table(flights, short=false)
		columns = [
			{ :title => 'Datum'           , :width => 14 },
			{ :title => 'Muster'          , :width => 12 },
			{ :title => 'Kennzeichen'     , :width => 16 },
			{ :title => 'Flugzeugführer'  , :width => 20 },
			{ :title => 'Begleiter'       , :width => 20 },
			{ :title => 'Startart'        , :width => 11 },
			{ :title => 'Starort'         , :width => 15 },
			{ :title => 'Zielort'         , :width => 15 },
			{ :title => 'Start'           , :width => 12 },
			{ :title => 'Landung'         , :width => 12 },
			{ :title => 'Flugdauer'       , :width => 13 },
			{ :title => 'Bemerkungen'     , :width => 20 }
		]

		rows=flights.each_with_index.map { |flight, index| [
			flight.effective_date                         ,
			flight.the_plane.typ                              ,
			flight.the_plane.kennzeichen                      ,
			flight.effective_pilot_name             || "?",
			flight.effective_copilot_name                 ,
			flight.launch_type_pilot_log_designator || "?",
			flight.startort                               ,
			flight.zielort                                ,
			flight.effective_launch_time            || "?",
			flight.effective_landing_time           || "?",
			flight.effective_duration               || "?",
			flight.bemerkung                              
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

