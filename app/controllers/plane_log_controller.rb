require 'date'
require 'tmpdir'

class PlaneLogController < ApplicationController
	allow_local :index, :show

	def initialize
		@default_format="pdf"
	end

	def index
		@format=params['format'] || @default_format
		@formats=formats
		redirect_to_with_date :action=>'show', :format=>@format
	end

	def show
		@date_range=date_range(params['date'])
		@flights=Flight.find_by_date_range(@date_range, {:readonly=>true})

		format=params['format'] || @default_format

		@plane_log=Hash.new { |hash, key| hash[key]=[] }
		PlaneLog.create_for_flights(@flights).each_pair { |plane, log_entries|
			@plane_log[plane.verein]+=log_entries
		}

		@tables={}
		@plane_log.each_pair { |club, entries|
			@tables[club]=make_table(entries)
		}

		respond_to do |format|
			format.html { render 'plane_log'        ; set_filename "bordbuecher_#{date_range_filename(@date_range)}.html" }
			format.pdf  { render_pdf 'plane_log.tex'; set_filename "bordbuecher_#{date_range_filename(@date_range)}.pdf"  }
			format.tex  { render 'plane_log'        ; set_filename "bordbuecher_#{date_range_filename(@date_range)}.tex"  }
			#format.csv  { render 'plane_log'        ; set_filename "bordbuecher_#{date_range_filename(@date_range)}.csv"  }
			#format.xml  { render :xml => @flights   ; set_filename "bordbuecher_#{date_range_filename(@date_range)}.xml"  }
			#format.json { render :json => @flights  ; set_filename "bordbuecher_#{date_range_filename(@date_range)}.json" }
		end
	end

protected
	def formats
		[
			['PDF'  , 'pdf'  ],
			['HTML' , 'html' ],
			['LaTeX', 'latex']
		]
	end

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

