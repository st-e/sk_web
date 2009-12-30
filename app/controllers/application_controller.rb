# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	helper :all # include all helpers, all the time
	protect_from_forgery # See ActionController::RequestForgeryProtection for details

	before_filter :require_login

	# Scrub sensitive parameters from your log
	# filter_parameter_logging :password

	def render_pdf(template, options)
		Dir.mktmpdir { |dir|
			texfile="#{dir}/file.tex"
			dvifile="#{dir}/file.dvi"
			psfile="#{dir}/file.ps"
			pdffile="#{dir}/file.pdf"

			File.open(texfile, "w") { |file|
				file.write render_to_string(template)
			}

			# TODO error handling, for example: pstricks not installed
			# TODO option for calling latex 1/2/3 times (don't merge options below)
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
			# seems to work, but is not what we want). Maybe it will work with
			# :stream=>false.
			send_data File.read(pdffile), { :type => 'application/pdf', :disposition => 'inline' }.merge(options)
		}
	end

protected
	# Allow access to an action without being logged in
	def self.allow_public(*options)
		skip_before_filter :require_login, options
	end

	# Allow access to an action without being logged in from a local host
	def self.allow_local(*options)
		skip_before_filter :require_login, options
		before_filter :require_local_or_logged_in, options
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

