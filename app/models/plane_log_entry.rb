require 'text'
require 'hash_by'


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
#		@registration=flight.plane.kennzeichen
#		@date=flight.effective_time.date
#		@pilot_name=flight.pilot.formal_name
#		@min_passengers=@max_passengers=flight.num_people
#		@departure_airfield=flight.startort
#		@destination_airfield=flight.zielort
#		@departure_time=flight.startzeit
#		@landing_time=flight.landezeit
#		@num_landings=flight.anzahl_landungen
#		@operation_time=flight.duration
#		@comments=flight.bemerkung
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
			flight.plane.kennzeichen,
			flight.effective_time.date,
			flight.pilot.formal_name,
			flight.num_people,
			flight.num_people,
			flight.startort,
			flight.zielort,
			flight.startzeit,
			flight.landezeit,
			flight.anzahl_landungen,
			flight.duration,
			flight.bemerkung)
	end

	# Create an entry for a non-empty, sorted, list of flights which we know
	# can be merged. All flights must be of the same plane and on the same
	# date.
	def PlaneLogEntry.create_merged(flights)
		return nil if !flights || flights.empty?

		return create(flights[0]) if flights.size==1

		PlaneLogEntry.new(
			flights.first.plane.kennzeichen,
			flights.last.effective_time.date,
			flights.last.pilot.formal_name,
			flights.map { |flight| flight.num_people }.min,
			flights.map { |flight| flight.num_people }.max,
			flights.first.startort,
			flights.last.zielort,
			flights.first.startzeit,
			flights.last.landezeit,
			flights.inject(0) { |sum, flight| sum+flight.anzahl_landungen },
			flights.inject(0) { |sum, flight| sum+flight.duration },
			flights.map { |flight| flight.bemerkung }.reject { |comment| comment.blank? }.join('; '))

		# TODO count the number of towflights; add "Schleppflug" or
		# "Schleppflüge" to the comments list
	end
end
