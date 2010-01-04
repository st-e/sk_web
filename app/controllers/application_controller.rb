# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	helper :all # include all helpers, all the time
	protect_from_forgery # See ActionController::RequestForgeryProtection for details

	before_filter :require_login

	# Scrub sensitive parameters from your log
	# filter_parameter_logging :password

protected
	def generate_pdf(template)
		Dir.mktmpdir { |dir|
			texfile="#{dir}/file.tex"
			dvifile="#{dir}/file.dvi"
			psfile="#{dir}/file.ps"
			pdffile="#{dir}/file.pdf"

			File.open(texfile, "w") { |file|
				file.write render_to_string(template)
			}

			# TODO error handling, for example: pstricks not installed
			# TODO option for calling latex 1/2/3 times
			latexcommand="latex -interaction=nonstopmode -output-directory=#{dir} #{texfile}"
			dvipscommand="dvips -o #{psfile} #{dvifile}"
			pstopdfcommand="ps2pdf -sOutputFile=#{pdffile} #{psfile}"

			# We need to call LaTeX twice for lastpage to work. Twice is
			# sufficient because we're not displaying a TOC.
			system latexcommand
			system latexcommand
			system dvipscommand
			system pstopdfcommand

			# Note that we cannot use send_file here to send the PDF file
			# because it will be deleted after this method returns (render
			# seems to work, but is not what we want).
			File.read(pdffile)
		}
	end

	def render_pdf(template, options={})
		send_data generate_pdf(template), { :type => 'application/pdf', :disposition => 'inline' }.merge(options)
	end

	def set_filename(filename)
		response.headers["Content-Disposition"] = "inline; filename=#{filename}"
	end

	# Allow access to an action without being logged in
	def self.allow_public(*options)
		skip_before_filter :require_login, options
	end

	# Allow access to an action without being logged in from a local host
	def self.allow_local(*options)
		skip_before_filter :require_login, options
		before_filter :require_local_or_logged_in, options
	end

	def current_username
		session[:username]
	end

	def current_user
		return nil if !session[:username]
		User.find(session[:username])
	end

	def date_spec
		case params['date']
			when 'today'     then 'today'
			when 'yesterday' then 'yesterday'
			when 'single'    then sprintf("%04d-%02d-%02d", params['year'], params['month'], params['day'])
			when 'range'     then sprintf("%04d-%02d-%02d_%04d-%02d-%02d", params['start_year'], params['start_month'], params['start_day'], params['end_year'], params['end_month'], params['end_day'])
			else nil
		end
	end

	# Returns [first_time, last_time] where last_time is exclusive
	def time_range(date_spec)
		# Note that we store the date in a temporary variable in order to avoid
		# race conditions

		first_time=last_time=nil

		if date_spec=='today'
			date=Date.today
		elsif date_spec=='yesterday'
			date=Date.today-1
			# TODO ^...$
		elsif date_spec =~ /^\d\d\d\d-\d\d-\d\d$/
			date=Date.parse(date_spec)
			# TODO ^...$
		elsif date_spec =~ /^(\d\d\d\d-\d\d-\d\d)_(\d\d\d\d-\d\d-\d\d)$/
			first_time=Date.parse($1).midnight
			last_time =Date.parse($2).midnight+1.day
		else
			throw ArgumentError
		end

		# In some cases, we determined a single date
		first_time=date.midnight       if !first_time
		last_time= date.midnight+1.day if !last_time

		[first_time, last_time]
	end

	# Will redirect with the given options and :date=>date_spec
	# All variables needed by the template have to be set
	def redirect_to_with_date(redirect_options)
		# If no date is given, render the date selection form
		# TODO rename template to index and get rid of template parameter
		render and return if !params['date']

		# If no date specification could be constructed (invalid date type, for
		# example 'tomorrow'), redirect back
		ds=date_spec
		redirect_to and return if !ds

		# Redirect to the show action with the date specification
		redirect_to redirect_options.merge({ :date=>ds })
	end

private
	def require_login
		unless logged_in?
			flash[:error] = "Anmeldung erforderlich"
			session[:origin]=request.url
			redirect_to login_path
		end
	end

	def require_local_or_logged_in
		unless local? || logged_in?
			flash[:error] = "Anmeldung erforderlich, da der Zugang von einer nicht-lokalen Adresse erfolgt"
			session[:origin]=request.url
			redirect_to login_path
		end
	end
	
	def logged_in?
		!!session[:username]
	end

	def local?
		request.remote_ip == "127.0.0.1"
	end
end

