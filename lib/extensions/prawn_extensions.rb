# encoding: utf-8

require 'rubygems'

require 'prawn'
require 'prawn/layout'
require "prawn/measurement_extensions"
require "prawn/table"

class Prawn::Document
	attr_accessor :footer_margin, :header_margin
	attr_accessor :header_size, :table_size
	attr_accessor :left_header, :centered_header, :right_header
	attr_accessor :left_footer, :centered_footer, :right_footer

	def left_text(y, t)
		draw_text t, :at => [bounds.left, y]
	end

	def right_text(y, t)
		draw_text t, :at => [bounds.right-width_of(t), y]
	end

	def centered_text(y, t)
		draw_text t, :at => [bounds.left+bounds.width/2-width_of(t)/2, y]
	end

	def     left_header_text(t);     left_text(bounds.   top-font.ascender,  t) if t; end
	def centered_header_text(t); centered_text(bounds.   top-font.ascender,  t) if t; end
	def    right_header_text(t);    right_text(bounds.   top-font.ascender,  t) if t; end
	def     left_footer_text(t);     left_text(bounds.bottom+font.descender, t) if t; end
	def centered_footer_text(t); centered_text(bounds.bottom+font.descender, t) if t; end
	def    right_footer_text(t);    right_text(bounds.bottom+font.descender, t) if t; end


	def headings_box
		canvas do
			l=bounds.left+@page.margins[:left]
			r=bounds.right-@page.margins[:right]
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
				# text :at=> does not work as of Prawn 0.8.4. text_at, now
				# draw_text, is significantly faster anyway.
				draw_text(value.to_s, :at=>[cx+horizontal_margin, cy-h+vertical_margin+descender])
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
		self.line_width=0.5

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

	def section(*args)
		text *args
		move_down 0.4.cm
		yield
		move_down 1.cm
	end

	# before_render won't work because it's called after finalize_all_page_contents
	def render_headings
		page_count.times do |i|
			page=i+1
			go_to_page(page)
		 
			headings_box do
				font_size(@header_size) do
					yield page
				end
			end
		end
	end
end




