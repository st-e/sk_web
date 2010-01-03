require 'date'
require 'tmpdir'

class PlaneLogController < ApplicationController
	allow_local :only => [:index, :show]

	def initialize
		@default_format="html"
	end

	def index
		redirect_options={ :controller => 'plane_log', :action => 'show' }

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
			render "plane_log_date.html.erb"
		end
	end

	def show
		# TODO make function, and also use in flightlist_controller
		begin
			if params['date']=='today'
				date=Date.today
			elsif params['date']=='yesterday'
				date=Date.today-1
			elsif params['date'] =~ /\d\d\d\d-\d\d-\d\d/
				date=Date.parse(params['date'])
			end
		rescue ArgumentError
			# TODO: error message (flash message), redirect to form with (erroneous) values entered
			# flash[:notice] = 'Flight was successfully created.'
			redirect_to :action => 'index'
		end

		# TODO make function, and also use in flightlist_controller
		first_time=date.midnight
		last_time= date.midnight+1.day

		condition="(startzeit>=:first_time AND startzeit<:last_time) OR (landezeit>=:first_time AND landezeit<:last_time)"
		condition_values={ :first_time=>first_time, :last_time=>last_time }
		flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values])#.sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		format=params['format'] || @default_format

		@plane_log=Hash.new { |hash, key| hash[key]=[] }
		PlaneLog.create_for_flights(flights).each_pair { |plane, log_entries|
			@plane_log[plane.verein]+=log_entries
		}

		@tables={}
		@plane_log.each_pair { |club, entries|
			@tables[club]=make_table(entries)
		}

		@date=date


		# TODO disallow all but PDF for non-privileged users
		respond_to do |format|
			format.html { render 'plane_log'        ; set_filename "bordbuecher_#{date}.html" }
			format.pdf  { render_pdf 'plane_log.tex'; set_filename "bordbuecher_#{date}.pdf"  }
			format.tex  { render 'plane_log'        ; set_filename "bordbuecher_#{date}.tex"  }
#			format.csv  { render 'plane_log'        ; set_filename "bordbuecher_#{date}.csv"  }
#			format.xml  { render :xml => @flights   ; set_filename "bordbuecher_#{date}.xml"  }
#			format.json { render :json => @flights  ; set_filename "bordbuecher_#{date}.json" }
		end
	end

protected
	def make_table(entries)
		columns = [
			{ :title => 'Kennzeichen'      , :width => 17 },
			{ :title => 'Datum'            , :width => 15 },
			{ :title => 'Name'             , :width => 32 },
			{ :title => 'Insassen'         , :width => 11 },
			{ :title => 'Startort'         , :width => 24 },
			{ :title => 'Zielort'          , :width => 24 },
			{ :title => 'Startzeit'        , :width => 14 },
			{ :title => 'Landezeit'        , :width => 14 },
			{ :title => 'Anzahl Landungen' , :width => 25 },
			{ :title => 'Dauer'            , :width =>  8 }
		]

		rows=entries.map { |entry| [
			entry.registration          ,
			entry.date                  ,
			entry.pilot_name            ,
			entry.num_passengers_string ,
			entry.departure_airfield    ,
			entry.destination_airfield  ,
			entry.departure_time_string ,
			entry.landing_time_string   ,
			entry.num_landings          ,
			entry.duration_string       
		] }

		{ :columns => columns, :rows => rows, :data => entries }
	end
end

