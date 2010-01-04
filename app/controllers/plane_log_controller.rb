require 'date'
require 'tmpdir'

class PlaneLogController < ApplicationController
	allow_local :only => [:index, :show]

	def initialize
		@default_format="html"
	end

	def index
		@format=params['format'] || @default_format
		redirect_to_with_date :action=>'show', :format=>@format
	end

	def show
		date=params['date']
		first_time, last_time=time_range(date)

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
			#format.csv  { render 'plane_log'        ; set_filename "bordbuecher_#{date}.csv"  }
			#format.xml  { render :xml => @flights   ; set_filename "bordbuecher_#{date}.xml"  }
			#format.json { render :json => @flights  ; set_filename "bordbuecher_#{date}.json" }
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

