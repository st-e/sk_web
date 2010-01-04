require 'date'
require 'tmpdir'

class FlightlistController < ApplicationController
	allow_local :only => [:index, :show]

	def initialize
		@default_format="html"
	end

	# GET /flightList
	def index
		@format=params['format'] || @default_format
		redirect_to_with_date :action=>'show', :format=>@format
	end

	def show
		date=params['date']
		first_time, last_time=time_range(date)

		condition="(startzeit>=:first_time AND startzeit<:last_time) OR (landezeit>=:first_time AND landezeit<:last_time)"
		condition_values={ :first_time=>first_time, :last_time=>last_time }
		@flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values]).sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		format=params['format'] || @default_format
		@date=date
		# TODO ugly
		@table=make_table(@flights, format=='tex' || format =='pdf')

		# TODO disallow all but PDF for non-privileged users
		respond_to do |format|
			format.html { render 'flightlist'        ; set_filename "startkladde_#{date}.html" }
			format.pdf  { render_pdf 'flightlist.tex'; set_filename "startkladde_#{date}.pdf"  }
			format.tex  { render 'flightlist'        ; set_filename "startkladde_#{date}.tex"  }
			format.csv  { render 'flightlist'        ; set_filename "startkladde_#{date}.csv"  }
			#format.xml  { render :xml => @flights    ; set_filename "startkladde_#{date}.xml"  }
			#format.json { render :json => @flights   ; set_filename "startkladde_#{date}.json" }
		end
	end

protected
	def make_table(flights, short=false)
		columns = [
			{ :title => (short)?'Nr.'        :'Nr.'                   , :width =>  5 },
			{ :title => (short)?'Kennz.'     :'Kennzeichen'           , :width => 16 },
			{ :title => (short)?'Typ'        :'Typ'                   , :width => 20 },
			{ :title => (short)?'Pilot'      :'Pilot'                 , :width => 27 },
			{ :title => (short)?'Begleiter'  :'Begleiter'             , :width => 27 },
			{ :title => (short)?'Verein'     :'Verein'                , :width => 25 },
			{ :title => (short)?'SA'         :'Startart'              , :width =>  6 },
			{ :title => (short)?'Start'      :'Startzeit'             , :width =>  9 },
			{ :title => (short)?'Landg.'     :'Landezeit'             , :width =>  9 },
			{ :title => (short)?'Dauer'      :'Dauer'                 , :width =>  9 },
			{ :title => (short)?'Ld. Sfz.'   :'Landezeit Schleppflug' , :width => 11 },
			{ :title => (short)?'Dauer'      :'Dauer Schleppflug'     , :width =>  9 },
			{ :title => (short)?'#Ldg.'      :'Anzahl Landungen'      , :width =>  9 },
			{ :title => (short)?'Startort'   :'Startort'              , :width => 19 },
			{ :title => (short)?'Zielort'    :'Zielort'               , :width => 19 },
			{ :title => (short)?'Zielort SFZ':'Zielort Schleppflug'   , :width => 19 },
			{ :title => (short)?'Bemerkung'  :'Bemerkungen'           , :width => 22 }
		]

		rows=flights.each_with_index.map { |flight, index| [
			index+1                                       ,
			flight.effective_plane_registration     || "?",
			flight.effective_plane_type             || "?",
			flight.effective_pilot_name             || "?",
			flight.effective_copilot_name                 ,
			flight.effective_club                   || "?",
			flight.launch_type_text                       ,
			flight.effective_launch_time                  ,
			flight.effective_landing_time                 ,
			flight.effective_duration                     ,
			flight.effective_landing_time_towflight       ,
			flight.effective_duration_towflight           ,
			flight.anzahl_landungen                       ,
			flight.startort                               ,
			flight.zielort                                ,
			flight.effective_destination_towflight        ,
			flight.bemerkung
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

