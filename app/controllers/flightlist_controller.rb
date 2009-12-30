require 'date'
require 'tmpdir'

class FlightlistController < ApplicationController
	allow_local :only => [:index, :show]

	def initialize
		@default_format="html"
	end

	# GET /flightList
	def index
		redirect_options={ :controller => 'flightlist', :action => 'show' }

		format=params['format'] || @default_format
		redirect_options[:format]=format if format!=@default_format

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
			render "flightlist_date.html.erb"
		end
	end

	def show
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

		first_time=date.midnight
		last_time= date.midnight+1.day

		condition="(startzeit>=:first_time AND startzeit<:last_time) OR (landezeit>=:first_time AND landezeit<:last_time)"
		condition_values={ :first_time=>first_time, :last_time=>last_time }
		@flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values]).sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		@date=date

		format=params['format'] || @default_format

		# TODO disallow all but PDF for non-privileged users
		if format=='html'
			render 'flightlist.html'
			# TODO make a method (or can render do this? send_data can.)
			response.headers["Content-Disposition"] = "inline; filename=startkladde_#{date}.html"
		elsif format=='tex' || format=='latex'
			render :text => render_to_string('flightlist.tex'), :content_type => 'text/plain'
		elsif format=='csv'
			render :text => render_to_string('flightlist.csv'), :content_type => 'text/plain'
		elsif format=='pdf'
			render_pdf 'flightlist.tex', :filename => "startkladde_#{date}.pdf"
		else
			render :text => "Invalid format #{format}"
		end
	end
end

