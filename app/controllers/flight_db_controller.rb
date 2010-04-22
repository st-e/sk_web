require_dependency 'duration'

class FlightDbController < ApplicationController
	require_permission :read_flight_db, :index, :show

	def initialize
		@default_format="html"
		@default_data_format="default"
	end

	def index
		@format=params['format'] || @default_format
		@formats=formats
		parameters={}
		parameters[:format]=@format
		parameters[:towflights_extra]='true' if params['towflights_extra'].to_b
		parameters[:data_format]=params['data_format'] if params['data_format']!=@default_data_format
		redirect_to_with_date parameters.merge({:action=>'show'})
	end

	def show
		format=params['format'] || @default_format

		@date_range=date_range(params['date'])

		@flights=Flight.find_by_date_range(@date_range, :readonly=>true)
		@flights+=Flight.make_towflights(@flights) if params['towflights_extra'].to_b
		@flights.reject! { |flight| !flight.effective_time }
		@flights=@flights.sort_by { |flight| flight.effective_time }

		@data_format=params['data_format']
		if !@data_format
			@table=make_table(@flights)
		else
			@data_format_plugin=DataFormatPlugin.registered_plugins[@data_format]
			@table=@data_format_plugin.make_table(@flights)
		end


		respond_to do |format|
			format.html { render 'flight_db'        ; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.html" }
			#format.pdf  { render_pdf 'flight_db.tex'; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.pdf"  }
			#format.tex  { render 'flight_db'        ; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.tex"  }
			format.csv  { render 'flight_db'        ; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.csv"  }
			#format.xml  { render :xml => @flights   ; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.xml"  }
			#format.json { render :json => @flights  ; set_filename "flugdatenbank_#{date_range_filename(@date_range)}.json" }
		end
	end

	def self.data_format_options
		result=[["Standard", 'default']]
		
		result+=DataFormatPlugin.registered_plugins.to_a.map { |name, plugin|
			["#{plugin.title} (Plugin)", name]
		}
	end

protected
	def formats
		[
			['HTML' , 'html' ],
			['CSV'  , 'csv'  ]
		]
	end


	def make_table(flights)
		columns = [
			{ :title => 'Datum'                       },
			{ :title => 'Nummer'                      },
			{ :title => 'Kennzeichen'                 },
			{ :title => 'Typ'                         },
			{ :title => 'Flugzeug Verein'             },
			{ :title => 'Pilot Nachname'              },
			{ :title => 'Pilot Vorname'               },
			{ :title => 'Pilot Verein'                },
			{ :title => 'Pilot VID'                   },
			{ :title => 'Begleiter Nachname'          },
			{ :title => 'Begleiter Vorname'           },
			{ :title => 'Begleiter Verein'            },
			{ :title => 'Begleiter VID'               },
			{ :title => 'Flugtyp'                     },
			{ :title => 'Anzahl Landungen'            },
			{ :title => 'Modus'                       },
			{ :title => 'Startzeit'                   },
			{ :title => 'Landezeit'                   },
			{ :title => 'Flugdauer'                   },
			{ :title => 'Startart'                    },
			{ :title => 'Kennzeichen Schleppflugzeug' },
			{ :title => 'Modus Schleppflugzeug'       },
			{ :title => 'Landung Schleppflugzeug'     },
			{ :title => 'Startort'                    },
			{ :title => 'Zielort'                     },
			{ :title => 'Zielort Schleppflugzeug'     },
			{ :title => 'Bemerkungen'                 },
			{ :title => 'Abrechnungshinweis'          },
			{ :title => 'DBID'                        }
		]

		last_date=nil
		number=0

		rows=flights.map { |flight|
			date=flight.effective_date
			number=0 if last_date!=date
			last_date=date
			number+=1

			plane=flight.plane
			pilot=flight.pilot
			copilot=flight.copilot
			
			[
				date                                   ,
				number                                 ,
				flight.effective_plane_registration    ,
				flight.effective_plane_type            ,
				(plane)?(plane.club):("")              ,
				(pilot)?(pilot.last_name):("")         ,
				(pilot)?(pilot.first_name):("")        ,
				(pilot)?(pilot.club):("")              ,
				(pilot)?(pilot.club_id):("")           ,
				(copilot)?(copilot.last_name):("")     ,
				(copilot)?(copilot.first_name):("")    ,
				(copilot)?(copilot.club):("")          ,
				(copilot)?(copilot.club_id):("")       ,
				flight.flight_type_text                ,
				flight.num_landings                    ,
				flight.mode_text                       ,
				flight.effective_departure_time_text   ,
				flight.effective_landing_time_text     ,
				flight.effective_duration              ,
				flight.launch_method_text              ,
				flight.effective_towplane_registration ,
				flight.mode_text_towflight             ,
				flight.effective_landing_time_text_towflight,
				flight.departure_location              ,
				flight.landing_location                ,
				flight.towflight_landing_location      ,
				flight.comments                        ,
				flight.accounting_notes                ,
				flight.id                              
		] }

		{ :columns => columns, :rows => rows, :data => flights }
	end
end

