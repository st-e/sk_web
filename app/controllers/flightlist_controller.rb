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
		@date_range=date_range(params['date'])
		@flights=Flight.find_by_date_range(@date_range, :readonly=>true).sort_by { |flight| flight.effective_time }

		format=params['format'] || @default_format
		@table=self.make_table(@flights, format=='tex' || format =='pdf') # Ugly

		#f=File.new("/home/martin/tmp/ruby/table.marshal", 'w')
		#t={:columns=>@table[:columns], :rows=>@table[:rows]}
		#Marshal.dump t, f
		#f.close

		render_permission_denied and return if !format_available? format

		respond_to do |format|
			format.html { render 'flightlist'          ; set_filename "startkladde_#{date_range_filename(@date_range)}.html" }
			format.pdf  { @faux_template='flightlist'; @page_layout=:landscape;
				          render 'layouts/faux_layout' ; set_filename "startkladde_#{date_range_filename(@date_range)}.pdf"  }
			format.csv  { render 'flightlist'          ; set_filename "startkladde_#{date_range_filename(@date_range)}.csv"  }
#			format.pdf  { render_pdf_latex 'flightlist.tex'; set_filename "startkladde_#{date_range_filename(@date_range)}.pdf"  }
			#format.tex  { render 'flightlist'        ; set_filename "startkladde_#{date_range_filename(@date_range)}.tex"  }
			#format.xml  { render :xml => @flights    ; set_filename "startkladde_#{date_range_filename(@date_range)}.xml"  }
			#format.json { render :json => @flights   ; set_filename "startkladde_#{date_range_filename(@date_range)}.json" }
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
#	def generate_flightlist_prawn
#		generate_pdf_prawn do |pdf|
#		end
#	end

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
		when 'pdf'  : true
		when 'html' : current_user && current_user.has_permission?(:read_flight_db)
		when 'csv'  : current_user && current_user.has_permission?(:read_flight_db)
#		when 'latex': current_user && current_user.has_permission?(:read_flight_db)
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

