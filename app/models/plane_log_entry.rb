# encoding: utf-8

require_dependency 'duration'

class PlaneLogEntry
	attr_reader :registration
	attr_reader :date, :pilot_name
	attr_reader :min_passengers, :max_passengers
	attr_reader :departure_airfield, :destination_airfield
	attr_reader :departure_time, :landing_time, :num_landings, :operation_time
	attr_reader :comments

	def num_passengers_string
		return @min_passengers.to_s if @min_passengers==@max_passengers
		return "1/2" if @min_passengers==1 && @max_passengers==2

		# Should not happen: entries for non-gliders cannot be merged
		return "#{@min_passengers}-#{@max_passengers}"
	end

#				static Entry create (const Flight *flight, DataStorage &dataStorage);
#				static Entry create (const QList<const Flight *> flights, DataStorage &dataStorage);

	def date_string
		return nil if !@date
		date.to_s
	end

	def departure_time_string
		return nil if !@departure_time
		departure_time.strftime("%H:%M")
	end

	def landing_time_string
		return nil if !@landing_time
		landing_time.strftime("%H:%M")
	end

	def duration_string
		return nil if !@operation_time
		format_duration(@operation_time, false)
	end

#	def initialize(flight)
#		@registration=flight.plane.registration
#		@date=flight.effective_date
#		@pilot_name=flight.pilot.formal_name
#		@min_passengers=@max_passengers=flight.num_people
#		@departure_airfield=flight.departure_location
#		@destination_airfield=flight.landing_location
#		@departure_time=flight.departure_time
#		@landing_time=flight.landing_time
#		@num_landings=flight.num_landings
#		@operation_time=flight.duration
#		@comments=flight.comments
#	end

	def initialize(registration, date, pilot_name, min_passengers, max_passengers, departure_airfield, destination_airfield, departure_time, landing_time, num_landings, operation_time, comments)
		@registration=registration
		@date=date
		@pilot_name=pilot_name
		@min_passengers=min_passengers
		@max_passengers=max_passengers
		@departure_airfield=departure_airfield
		@destination_airfield=destination_airfield
		@departure_time=departure_time
		@landing_time=landing_time
		@num_landings=num_landings
		@operation_time=operation_time
		@comments=comments
	end

	def PlaneLogEntry.create(flight)
		PlaneLogEntry.new(
			flight.plane.registration,
			flight.effective_date,
			flight.effective_pilot_name,
			flight.num_people,
			flight.num_people,
			flight.departure_location,
			flight.landing_location,
			(flight.departs_here?)?(flight.departure_time):nil,
			(flight.  lands_here?)?(flight.  landing_time):nil,
			(flight.  lands_here?)?(flight.num_landings):nil,
			flight.duration,
			flight.comments)
	end

	# Create an entry for a non-empty, sorted, list of flights which we know
	# can be merged. All flights must be of the same plane and on the same
	# date.
	def PlaneLogEntry.create_merged(flights)
		return nil if !flights || flights.empty?

		return create(flights[0]) if flights.size==1

		PlaneLogEntry.new(
			flights.first.plane.registration,
			flights.last.effective_date,
			flights.last.effective_pilot_name,
			flights.map { |flight| flight.num_people }.min,
			flights.map { |flight| flight.num_people }.max,
			flights.first.departure_location,
			flights.last.landing_location,
			flights.first.departure_time,
			flights.last.landing_time,
			flights.inject(0) { |sum, flight| sum+ flight.num_landings   },
			flights.inject(0) { |sum, flight| sum+(flight.duration || 0) },
			flights.map { |flight| flight.comments }.reject { |comment| comment.blank? }.join('; '))
	end
end
