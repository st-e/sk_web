require 'date'
require 'tmpdir'

class FlightDbController < ApplicationController
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

		# TODO this has a lot of code duplication with plane_log_controller

		condition="(startzeit>=:first_time AND startzeit<:last_time) OR (landezeit>=:first_time AND landezeit<:last_time)"
		condition_values={ :first_time=>first_time, :last_time=>last_time }
		@flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values]).sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		format=params['format'] || @default_format

		@date=date

		@table=make_table(@flights)

		respond_to do |format|
			format.html { render 'flight_db'        ; set_filename "flugdatenbank_#{date}.html" }
			#format.pdf  { render_pdf 'flight_db.tex'; set_filename "flugdatenbank_#{date}.pdf"  }
			#format.tex  { render 'flight_db'        ; set_filename "flugdatenbank_#{date}.tex"  }
			format.csv  { render 'flight_db'        ; set_filename "flugdatenbank_#{date}.csv"  }
			#format.xml  { render :xml => @flights   ; set_filename "flugdatenbank_#{date}.xml"  }
			#format.json { render :json => @flights  ; set_filename "flugdatenbank_#{date}.json" }
		end
	end

protected
	def make_table(flights)
		columns = [
			{ :title => 'Datum'                       , :width => 0 },
			{ :title => 'Nummer'                      , :width => 0 },
			{ :title => 'Kennzeichen'                 , :width => 0 },
			{ :title => 'Typ'                         , :width => 0 },
			{ :title => 'Flugzeug Verein'             , :width => 0 },
			{ :title => 'Pilot Nachname'              , :width => 0 },
			{ :title => 'Pilot Vorname'               , :width => 0 },
			{ :title => 'Pilot Verein'                , :width => 0 },
			{ :title => 'Pilot VID'                   , :width => 0 },
			{ :title => 'Begleiter Nachname'          , :width => 0 },
			{ :title => 'Begleiter Vorname'           , :width => 0 },
			{ :title => 'Begleiter Verein'            , :width => 0 },
			{ :title => 'Begleiter VID'               , :width => 0 },
			{ :title => 'Flugtyp'                     , :width => 0 },
			{ :title => 'Anzahl Landungen'            , :width => 0 },
			{ :title => 'Modus'                       , :width => 0 },
			{ :title => 'Startzeit'                   , :width => 0 },
			{ :title => 'Landezeit'                   , :width => 0 },
			{ :title => 'Flugdauer'                   , :width => 0 },
			{ :title => 'Startart'                    , :width => 0 },
			{ :title => 'Kennzeichen Schleppflugzeug' , :width => 0 },
			{ :title => 'Modus Schleppflugzeug'       , :width => 0 },
			{ :title => 'Landung Schleppflugzeug'     , :width => 0 },
			{ :title => 'Startort'                    , :width => 0 },
			{ :title => 'Zielort'                     , :width => 0 },
			{ :title => 'Zielort Schleppflugzeug'     , :width => 0 },
			{ :title => 'Bemerkungen'                 , :width => 0 },
			{ :title => 'Abrechnungshinweis'          , :width => 0 },
			{ :title => 'DBID'                        , :width => 0 }
		]

		last_date=nil
		number=0

		rows=flights.map { |flight|
			# TODO works?
			date=flight.effective_date
			number=0 if last_date!=date
			last_date=date
			number+=1

			plane=flight.the_plane
			pilot=flight.the_pilot
			copilot=flight.the_copilot
			
			[
				date                                   ,
				number                                 ,
				flight.effective_plane_registration    ,
				flight.effective_plane_type            ,
				(plane)?(plane.verein):("")            ,
				(pilot)?(pilot.nachname):("")          ,
				(pilot)?(pilot.vorname):("")           ,
				(pilot)?(pilot.verein):("")            ,
				(pilot)?(pilot.vereins_id):("")        ,
				(copilot)?(copilot.nachname):("")      ,
				(copilot)?(copilot.vorname):("")       ,
				(copilot)?(copilot.verein):("")        ,
				(copilot)?(copilot.vereins_id):("")    ,
				flight.flight_type_text                ,
				flight.anzahl_landungen                ,
				flight.mode_text                       ,
				flight.effective_launch_time           ,
				flight.effective_landing_time          ,
				flight.effective_duration              ,
				flight.launch_type_text                ,
				flight.effective_towplane_registration ,
				flight.mode_text_towflight             ,
				flight.effective_landing_time_towflight,
				flight.startort                        ,
				flight.zielort                         ,
				flight.zielort_sfz                     ,
				flight.bemerkung                       ,
				flight.abrechnungshinweis              ,
				flight.id                              
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

