# TODO lib
require 'rubygems'

require 'prawn'
require "prawn/measurement_extensions"
require "prawn/table"

class Prawn::Document
	attr_accessor :footer_margin, :header_margin
	attr_accessor :header_size, :table_size
	attr_accessor :left_header, :centered_header, :right_header
	attr_accessor :left_footer, :centered_footer, :right_footer

	def left_text(y, t)
		text_at t, :at => [bounds.left, y]
	end

	def right_text(y, t)
		text_at t, :at => [bounds.right-width_of(t), y]
	end

	def centered_text(y, t)
		text_at t, :at => [bounds.left+bounds.width/2-width_of(t)/2, y]
	end

	def     left_header_text(t);     left_text(bounds.   top-font.ascender,  t) if t; end
	def centered_header_text(t); centered_text(bounds.   top-font.ascender,  t) if t; end
	def    right_header_text(t);    right_text(bounds.   top-font.ascender,  t) if t; end
	def     left_footer_text(t);     left_text(bounds.bottom+font.descender, t) if t; end
	def centered_footer_text(t); centered_text(bounds.bottom+font.descender, t) if t; end
	def    right_footer_text(t);    right_text(bounds.bottom+font.descender, t) if t; end


	def headings_box
		canvas do
			l=bounds.left+@margins[:left]
			r=bounds.right-@margins[:right]
			t=bounds.top-(@header_margin||0)
			b=bounds.bottom+(@footer_margin||0)
			bounding_box([l,t], :width=>(r-l), :height=>(t-b)) do
				yield
			end
		end
	end

	def save_state(&block)
		add_content "q"
		yield
		add_content "Q"
	end

	def clip_box(x, y, w, h, stroke=false, &block)
		save_state do
			self.line_width=0.5

			add_content "W" # Start clip path

			# Draw the cell outline
			add_content "#{x  } #{y  } m" # Move to upper left corner
			add_content "#{x  } #{y-h} l" # Line to lower left corner
			add_content "#{x+w} #{y-h} l" # Line to lower right corner
			add_content "#{x+w} #{y  } l" # Line to upper right corner

			add_content (stroke)?"s":"n" # Close path and stroke

			yield
		end
	end


	def render_table_row(column_widths, values)
		horizontal_margin=2
		vertical_margin=0.5

		# Let's use local coordinates. This means we have to add origin x and y for
		# the absolute coordinates used in add_content.
		ox=bounds.absolute_left
		oy=bounds.absolute_bottom

		# Upper left cell corner
		cx=0
		cy=y-oy

		# Cell height
		h=font.height+2*vertical_margin
		descender=font.descender

		return false if cy-h<=bounds.bottom

		values.each_with_index { |value, index|
			# Cell width
			w=column_widths[index]


			clip_box cx+ox, cy+oy, w, h, true do
				# text_at is significantly faster than text :at=>
				text_at(value.to_s, :at=>[cx+horizontal_margin, cy-h+vertical_margin+descender])
			end

			# Move to the next cell
			cx+=w
		}

		self.y-=h

		true
	end

	def render_table_header(column_widths, values)
		ok=render_table_row column_widths, values
		move_down 2 if ok
		ok
	end

	def render_table(table)
		# Extract some values from the table
		columns=table[:columns]
		rows=table[:rows]

		header_values=columns.map { |column| column[:title] }

		# Determine the column widths
		column_widths=columns.map { |column| column[:width].mm }

		# Distribute extra space according to stretch factors
		total_stretch=columns.sum { |column| column[:stretch] || 0 }
		if total_stretch>0
			total_width=column_widths.sum
			extra_width_per_stretch = (bounds.width - total_width)/total_stretch

			column_widths.size.times { |i|
				column_widths[i] += extra_width_per_stretch * (columns[i][:stretch] || 0)
			}
		end
		
		# Create a column width hash
		column_widths_hash={}
		column_widths.each_with_index { |width, index| column_widths_hash[index]=width.max(0) }

		# Render the table header
		render_table_header(column_widths_hash, header_values)

		rows.each { |row|
			# Render the current table row
			if !render_table_row column_widths, row
				# Oops...the row didn't fit on the page

				# Start a new page
				start_new_page

				# Render the table header again
				render_table_header(column_widths_hash, header_values)

				# Render the current row again
				render_table_row column_widths, row
			end
		}
	end

	def paragraph
		move_down 0.5.cm
	end

	# before_render won't work because it's called after finalize_all_page_contents
	def render_headings
		page_count.times do |i|
			page=i+1
			go_to_page(page)
		 
			headings_box do
				font_size (@header_size) do
					yield page
				end
			end
		end
	end
end



module Rendering
	# The message will not be escaped
	def render_error(message, options={})
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

