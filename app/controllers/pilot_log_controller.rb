require 'date'
require 'tmpdir'

class PilotLogController < ApplicationController
	def initialize
		@default_format="html"
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

		redirect_options={ :controller => 'pilot_log', :action => 'show' }

		format=params['format'] || @default_format
		redirect_options[:format]=format

		if params['date_spec']=='today'
			redirect_options[:date]='today'
			redirect_to redirect_options
		elsif params['date_spec']=='yesterday'
			redirect_options[:date]='yesterday'
			redirect_to redirect_options
		elsif params['date_spec']=='single' 
			if params.has_key?('year') && params.has_key?('month') && params.has_key?('day')
				# TODO must be dddd-dd-dd (0 padding)
				redirect_options[:date]="#{params['year']}-#{params['month']}-#{params['day']}"
				redirect_to redirect_options
			else
				redirect_to
			end
		else
			@format=format
			render "pilot_log_date"
		end
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

		# TODO use function, see plane_log_controller
		begin
			if params['date']=='today'
				date=Date.today
			elsif params['date']=='yesterday'
				date=Date.today-1
			elsif params['date'] =~ /\d\d\d\d-\d\d-\d\d/
				date=Date.parse(params['date'])
			# TODO or date range
			end
		rescue ArgumentError
			# TODO: error message (flash message), redirect to form with (erroneous) values entered
			# flash[:notice] = 'Flight was successfully created.'
			redirect_to :action => 'index'
		end

		# TODO use function, see plane_log_controller
		# TODO this has a lot of code duplication with plane_log_controller
		first_time=date.midnight
		last_time= date.midnight+1.day

		condition="pilot=:person AND ((startzeit>=:first_time AND startzeit<:last_time) OR (landezeit>=:first_time AND landezeit<:last_time))"
		condition_values={ :person=>@person.id, :first_time=>first_time, :last_time=>last_time }
		# TODO have to sort?
		@flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values])#.sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		format=params['format'] || @default_format

		@date=date
		@table=make_table(@flights)

		respond_to do |format|
			format.html { render 'pilot_log'        ; set_filename "flugbuch_#{date}.html" }
			format.pdf  { render_pdf 'pilot_log.tex'; set_filename "flugbuch_#{date}.pdf"  }
			format.tex  { render 'pilot_log'        ; set_filename "flugbuch_#{date}.tex"  }
			format.csv  { render 'pilot_log'        ; set_filename "flugbuch_#{date}.csv"  }
#			format.xml  { render :xml => @flights   ; set_filename "flugbuch_#{date}.xml"  }
#			format.json { render :json => @flights  ; set_filename "flugbuch_#{date}.json" }
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

