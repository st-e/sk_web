# encoding: utf-8

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


