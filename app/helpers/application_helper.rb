require 'util'
require 'erb'
require 'csv'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	def yesno(value)
		(value)?"Ja":"Nein"
	end

	def latex_escape(value)
		return nil if !value
		
		# This is a bit ugly because \ gets \textbackslash{}, and { gets \{
		# (likewise, } gets \}), so each of these would escape the
		# already-escaped other. Thus, we only replace \ if not followed by {
		# or } (that is, either a different character or the end of the line).
		# Also, \, { and } are replaced first because they also occur in many
		# other subsitutions
		value.to_s \
			.gsub('{', '\\{') \
			.gsub('}', '\\}') \
			.gsub(/\\([^{}])/, '\\textbackslash{}\\1') \
			.gsub(/\\$/, '\\textbackslash{}') \
			.gsub('$', '\\$') \
			.gsub('%', '\\%') \
			.gsub('_', '\\_') \
			.gsub('&', '\\&') \
			.gsub('#', '\\#') \
			.gsub('^', '\\textasciicircum{}') \
			.gsub('~', '\\textasciitilde{}') \
			.gsub('"', '\\textquotedbl{}') \
			.gsub('-', '{-}') \
			.gsub(',', '{,}') \
			.gsub('`', '{`}') \
			.gsub("'", "{'}")
			# [-,`'] can have special meanings (---, ,,, ``, '')
			# Seems like guilsingl{left,right} don't work properly
			# .gsub('<', '\\guilsinglleft{}')
			# .gsub('>', '\\guilsinglright{}')
	end

	alias_method :l, :latex_escape

	def version_string
		ruby="Ruby #{RUBY_VERSION}"
		rails="Rails #{Rails::VERSION::STRING}"
		mysql="MySQL #{Mysql.client_version.to_s.sub(/^(.)(..)(..)/, '\\1.\\2.\\3')}"
		"sk_web Version 2.0 (experimental)/#{ruby}/#{rails}/#{mysql}"
		# RUBY_RELEASE_DATE
	end

	# The argument will not be HTML escaped!
	def page_title(title)
		content_for :title do
			title
		end
		"<h2 class=\"page_title\">#{title}</h2>"
	end


	class TableForRowContext
		include ERB::Util

		def initialize(options={})
			@tag=(options[:header])?"th":"td"
		end

		def cell(contents, options={})
			if contents.is_a? Array
				contents.map { |element| cell element }
			else
				colspan=" colspan=\"#{options[:colspan]}\"" if options[:colspan]
				klass  =  " class=\"#{options[:class  ]}\"" if options[:class]
				style  =  " style=\"#{options[:style  ]}\"" if options[:style]
				"<#{@tag}#{colspan}#{klass}#{style}>#{contents.to_s}</#{@tag}>"
			end
		end

		def text(contents, options={})
			if contents.is_a? Array
				cell(contents.map { |element| h element }, options)
			else
				cell(h(contents), options)
			end
		end

		def hidden(options={})
			options=options.dup
			options[:style]="visibility:hidden; #{options[:style]}"
			cell("", options)
		end
	end

	class TableForContext
		def initialize(target, array)
			@target=target
			@array=array
		end

		def header_row(options={})
			classes=["header"]
			classes << "nobreak" if options[:nobreak]

			@target.concat "<tr class=\"#{classes.join(' ')}\">"
			yield TableForRowContext.new(:header=>true)
			@target.concat '</tr>'
		end

		def body_row(options={})
			classes=["data"]
			classes << "nobreak" if options[:nobreak]

			@target.concat "<tr class=\"#{classes.join(' ')}\">"
			yield TableForRowContext.new
			@target.concat '</tr>'
		end

		def body(options={})
			body_context=TableForRowContext.new

			@array.each_with_index { |element, index|
				classes=["data#{index%2}"]
				classes << "nobreak" if options[:nobreak]

				@target.concat "<tr class=\"#{classes.join(' ')}\">"
				yield body_context, element
				@target.concat '</tr>'
			}
		end
	end

	def table_for(array, options={})
		classes=["list"]
		classes << "nobreak" if options[:nobreak]

		concat "<table class=\"#{classes.join(' ')}\">"
		yield TableForContext.new(self, array)
		concat '</table>'
	end

	def german_format
		"%d.%m.%Y"
	end

	def date_formatter(format, strip_leading_zeros=false)
		lambda { |date|
			string=date.strftime(format)
			string.gsub!(/(^|\.)0/, '\1') if strip_leading_zeros
			string
		}
	end

	def make_csv
		out=""

		CSV::Writer.generate(out) { |csv|
			yield csv
		}

		out
	end
end

