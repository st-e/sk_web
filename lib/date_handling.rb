# encoding: utf-8

module DateHandling
	def parse_date(string)
		if string
			Date.parse(string)
		else
			nil
		end
	end

	# A date specification is a string describing a date or a date range. The
	# kind of date specification is determined from he 'date' parameter, and
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
		render and return if !params['date']

		# If no date specification could be constructed (invalid date type, for
		# example 'tomorrow'), redirect back
		ds=date_spec
		redirect_to and return if !ds

		# Redirect to the show action with the date specification
		redirect_to redirect_options.merge({ :date=>ds })
	end

	def german_format
		"%d.%m.%Y"
	end

	def iso_format
		"%Y-%m-%d"
	end

	def german_month_names
		[
			"Januar",
			"Februar",
			"März",
			"April",
			"Mai",
			"Juni",
			"Juli",
			"August",
			"September",
			"Oktober",
			"November",
			"Dezember"
		]
	end

	def date_formatter(format, strip_leading_zeros=false)
		lambda { |date|
			return nil if !date
			string=date.strftime(format)
			string.gsub!(/(^|\.|-)0/, '\1') if strip_leading_zeros
			string
		}
	end
end

