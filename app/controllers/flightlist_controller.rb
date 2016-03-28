# encoding: utf-8

class FlightlistController < ApplicationController
	allow_local :index, :show

	def initialize
		@default_format="pdf"
	end

	def index
		@format=params['format'] || @default_format
		@formats=available_formats
		redirect_to_with_date :action=>'show', :format=>@format
	end

	def show
		# Check for format errors outside of the respond_to block because we
		# cannot output an error message within the block because we can't
		# override the format to HTML. We still check if the format is allowed 
		# within the respond_to block because respond_to may take more
		# information in account than just params['format'].
		format=params[:format]
		(render_error "Kein Format angegeben" and return) if !format
		(render_permission_denied             and return) if !format_available?(format)

		@date_range=date_range(params['date'])
		@flights=Flight.find_by_date_range(@date_range, :readonly=>true).sort_by { |flight| flight.effective_time }
		@table=self.class.make_table(@flights, format=='pdf') # Ugly

		respond_to do |format|
			filename_base="startkladde_#{date_range_filename(@date_range)}"

			format.html { render_if_allowed 'flightlist', 'html', "#{filename_base}.html" }
			format.pdf  { render_if_allowed 'flightlist', 'pdf' , "#{filename_base}.pdf" , :page_layout=>:landscape }
			format.csv  { render_if_allowed 'flightlist', 'csv' , "#{filename_base}.csv"  }
			format.any  { render_permission_denied }
		end
	end

	def self.dump_flightlist_today
		dh=Object.new
		dh.class_eval do
			include DateHandling
		end

		@date_range=dh.date_range('today')
		@flights=Flight.find_by_date_range(@date_range, :readonly=>true).sort_by { |flight| flight.effective_time }
		@table=make_table(@flights, false)

		puts make_csv { |csv|
			csv << @table[:columns].map { |column| column[:title] }
			@table[:rows].each { |row|
				csv << row
			}
		}
	end

protected
	def available_formats
		formats.select { |format| format_available? format[1] }
	end

	def formats
		[
			['PDF'  , 'pdf'  ],
			['HTML' , 'html' ],
			['CSV'  , 'csv'  ]
#			['LaTeX', 'latex']
		]
	end

	def format_available?(format)
		case format
		when 'pdf'  then true
		when 'html' then current_user && current_user.has_permission?(:read_flight_db)
		when 'csv'  then current_user && current_user.has_permission?(:read_flight_db)
#		when 'latex'then current_user && current_user.has_permission?(:read_flight_db)
		else false
		end
	end

	def self.make_table(flights, short=false)
		columns = [
			{ :title => (short)?'Nr.'         :'Nr.'                   , :width =>  5 },
			{ :title => (short)?'Kennz.'      :'Kennzeichen'           , :width => 16 },
			{ :title => (short)?'Typ'         :'Typ'                   , :width => 20 },
			{ :title => (short)?'Pilot'       :'Pilot'                 , :width => 27 },
			{ :title => (short)?'Begleiter'   :'Begleiter'             , :width => 27 },
			{ :title => (short)?'Verein'      :'Verein'                , :width => 25 },
			{ :title => (short)?'SA'          :'Startart'              , :width =>  6 },
			{ :title => (short)?'Start'       :'Startzeit'             , :width =>  9 },
			{ :title => (short)?'Landg.'      :'Landezeit'             , :width =>  9 },
			{ :title => (short)?'Dauer'       :'Dauer'                 , :width =>  9 },
			{ :title => (short)?'Ld. Sfz.'    :'Landezeit Schleppflug' , :width => 11 },
			{ :title => (short)?'Dauer'       :'Dauer Schleppflug'     , :width =>  9 },
			{ :title => (short)?'#Ldg.'       :'Anzahl Landungen'      , :width =>  9 },
			{ :title => (short)?'Startort'    :'Startort'              , :width => 19 },
			{ :title => (short)?'Zielort'     :'Zielort'               , :width => 19 },
			{ :title => (short)?'Zielort SFZ' :'Zielort Schleppflug'   , :width => 19 },
			{ :title => (short)?'Bemerkungen' :'Bemerkungen'           , :width => 22, :stretch=>1}
		]

		rows=flights.each_with_index.map { |flight, index| [
			index+1                                       ,
			flight.effective_plane_registration     || "?",
			flight.effective_plane_type             || "?",
			flight.effective_pilot_name             || "?",
			flight.effective_copilot_name                 ,
			flight.effective_club                   || "?",
			flight.launch_method_text                     ,
			flight.effective_departure_time_text          ,
			flight.effective_landing_time_text            ,
			flight.effective_duration                     ,
			flight.effective_landing_time_text_towflight  ,
			flight.effective_duration_towflight           ,
			flight.num_landings                           ,
			flight.departure_location                     ,
			flight.landing_location                       ,
			flight.effective_destination_towflight        ,
			flight.comments
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

