module Rendering
	def render_error(message)
		flash.now[:error]=message
		render :text=>"", :layout=>true
	end

	def generate_pdf(template)
		Dir.mktmpdir { |dir|
			texfile="#{dir}/file.tex"
			dvifile="#{dir}/file.dvi"
			psfile="#{dir}/file.ps"
			pdffile="#{dir}/file.pdf"

			File.open(texfile, "w") { |file|
				file.write render_to_string(template)
			}

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

	def store_origin(origin=nil)
		origin=request.referer if !origin
		session[:origin]=origin
	end

	def redirect_to_origin(*default_args)
		if session[:origin]
			redirect_to session[:origin]
			session[:origin]=nil
		else
			redirect_to(*default_args)
		end
	end

	def redirect_to_login(message="Für diese Aktion ist eine Anmeldung erforderlich.")
		flash[:error]=message
		store_origin request.url
		redirect_to login_path
	end

end

