# encoding: utf-8

module WillPaginate
	class Collection
		include ERB::Util

		def page_first
			offset+1
		end

		def page_last
			offset+length
		end

		def singular_name
			return "Eintrag" if empty?
			first.class.name.underscore.sub('_', ' ')
		end

		def page_info(singular=nil, plural=nil, options = {})
			singular ||= singular_name
			plural   ||= singular.pluralize

			if total_pages < 2
				case size
				when 0; "Keine #{h plural}"
				when 1; "<b>1</b> #{h singular}"
				else;   "<b>#{size}</b> #{h plural}"
				end
			else
				%{%s <b>%d</b> bis <b>%d</b> von <b>%d</b>} %
					[h(plural.capitalize), page_first, page_last, total_entries]
			end
		end
	end

	class ButtonRenderer <LinkRenderer
		def page_link(page, text, attributes = {})
			# Enabled button
			@template.submit_tag text, :name => "page_#{page}"
		end

		def page_span(page, text, attributes = {})
			# A disabled link: either the current page (page!=nil) or a
			# disabled prev/next button

			if page
				# Current button
				@template.submit_tag text, attributes.merge({ :name => "page_#{page}", :disabled=>true })
			else
				# Disabled prev/next button
				@template.submit_tag text, attributes.merge({ :name => "disabled", :disabled=>true })
			end
		end
	end
end

WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&laquo; Zurück'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Vor &raquo;'

