# encoding: utf-8

module Rendering
	# The message will not be escaped
	# Note: this does not work in or after a respond_to block when the format
	# is something else than HTML. More precisely: in or after such a block,
	# we can render text, but the layout will not be rendered (even if
	# :layout=>true is specified) and the content type will not be changed.
	# Setting response.template.template_format and deleting
	# respons.header["Content-Disposition"] seems to yield identical outputs
	# (including headers), but Firefox still interprets it as PDF if a PDF was
	# requested.
	def render_error(message, options={})
		# Allow doing this even after we have rendered
		erase_results if performed?

		# Always render as HTML, regardless of format
		# Note: this does not not work in an respond_to block. How can we do
		# this? erase_result does not help.
		#response.template.template_format='html'
		#response.headers.delete "Content-Disposition"
		#response.content_type='text/html'
		params['format']='html'

		flash.now[:error]=message
		render({:text=>"", :layout=>true}.merge(options))
	end

	def generate_pdf_latex(template)
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

	def render_pdf_latex(template, options={})
		render_pdf generate_pdf_latex(template), options
	end

	def render_pdf(pdf, options={})
		send_data pdf, { :type => 'application/pdf', :disposition => 'inline' }.merge(options)
	end

	#def generate_pdf_prawn
		#pdf.render_file('prawn.pdf')
		#pdf.render
	#end

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

