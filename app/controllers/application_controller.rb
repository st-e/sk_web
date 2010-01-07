# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	helper :all # include all helpers, all the time
	protect_from_forgery # See ActionController::RequestForgeryProtection for details

	filter_parameter_logging :password, :password_confirmation, :current_password

	# By default, all actions of all controllers reqire a user to be logged in.
	# Individual controllers or actions can be set up to be allowed without
	# login, potentially only from local addresses. See allow_public and
	# allow_local.
	before_filter :require_login

	# TODO
	#before_filter :check_permissions


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

	# Allows access without login
	def self.allow_public(*options)
		# The :require_login before filter is installed by default
		skip_before_filter :require_login, options
	end

	# Allow access without login from a local host
	def self.allow_local(*options)
		# The :require_login before filter is installed by default
		skip_before_filter :require_login, options
		before_filter :require_local_or_login, options
	end

	def current_username
		session[:username]
	end

	def current_user
		return nil if !session[:username]
		User.find(session[:username])
	end

	# A date specification is a string describing a date or a date range. The
	# kind of date specification is determined from he 'date' parameter. And
	# potentially other parameters.
	#
	# date param |date specification    |other params
	# -----------+----------------------+---------------------
	# today      |'today'               |
	# yesterday  |'yesterday'           |
	# single     |xxxx-xx-xx            |single_date
	# range      |xxxx-xx-xx_xxxx-xx-xx |first_date, last_date
	def date_spec
		case params['date']
			when 'today'     then 'today'
			when 'yesterday' then 'yesterday'
			when 'single'    then
				single=params['single_date']
				Date.parse(single).to_s
			when 'range'     then
				first =params['first_date' ]
				last  =params['last_date'  ]
				"#{Date.parse(first)}_#{Date.parse(last)}"
			else nil
		end
	end

	# Constructs a range of dates from a date specification
	def date_range(date_spec)
		# Note that in the case of 'today' and 'yesterday', we store the date
		# in a temporary variable in order to avoid race conditions

		if date_spec=='today'
			date=Date.today
			date..date
		elsif date_spec=='yesterday'
			date=Date.today-1
			date..date
		elsif date_spec =~ /^\d\d\d\d-\d\d-\d\d$/
			date=Date.parse(date_spec)
			date..date
		elsif date_spec =~ /^(\d\d\d\d-\d\d-\d\d)_(\d\d\d\d-\d\d-\d\d)$/
			first_date=Date.parse($1)
			last_date =Date.parse($2)
			first_date..last_date
		else
			raise ArgumentError, "Invalid date specification"
		end
	end

	def date_range_filename(date_range)
		first=date_range.begin
		last=date_range.end
		last=last-1 if date_range.exclude_end?

		if first==last
			first.to_s
		else
			"#{first}_#{last}"
		end
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

	def store_origin(origin=nil)
		origin=request.referer if !origin
		session[:origin]=origin
	end

	# TODO: if multiple (user) edit windows are opened, all of them will
	# redirect back to the origin of the last one
	def redirect_to_origin(*default_args)
		if session[:origin]
			redirect_to session[:origin]
			session[:origin]=nil
		else
			redirect_to(*default_args)
		end
	end


private
	# This filter requires a user to be logged in.
	def require_login
		unless logged_in?
			flash[:error] = "Anmeldung erforderlich"
			store_origin request.url
			redirect_to login_path
		end
	end

	# This filter required a user to be logged in unless the connection is made
	# from a local address (see the local? method), in which case no login is
	# required (but doesn't hurt either).
	def require_local_or_login
		unless local? || logged_in?
			flash[:error] = "Anmeldung erforderlich, da der Zugang von einer nicht-lokalen Adresse erfolgt"
			store_origin request.url
			redirect_to login_path
		end
	end

	# TODO
	#def check_permissions
	#	render :text => "Insufficient permissions"
	#end
	
	def logged_in?
		!!session[:username]
	end

	def local?
		# TODO read from configuration file
		request.remote_ip == "127.0.0.1"
	end
end

