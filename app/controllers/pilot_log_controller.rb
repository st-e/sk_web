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
		@flights=Flight.all(:readonly=>true, :conditions => [condition, condition_values])#.sort_by { |flight| flight.effective_time }
		# TODO filter out flights that have not started/landed (that is, there
		# is a time, but the corresponding flags are not set), or where the
		# launch/landing time is not valid (due to flight mode)

		format=params['format'] || @default_format

		@date=date

		if format=='html'
			# TODO set the file name here (via header)
			render 'pilot_log.html'
		elsif format=='tex' || format=='latex'
			render :text => render_to_string('pilot_log.tex'), :content_type => 'text/plain'
		elsif format=='csv'
			render :text => render_to_string('pilot_log.csv'), :content_type => 'text/plain'
		elsif format=='pdf'
			# TODO include pilot name in filename
			render_pdf 'pilot_log.tex', :filename => "flugbuch_#{date}.pdf" # TODO date spec
		else
			render :text => "Invalid format #{format}"
		end
	end
end

