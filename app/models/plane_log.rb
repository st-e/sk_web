# encoding: utf-8

class PlaneLog
	# Create a log for flights of a single plane, merging if possible
	# Returns an array of entries
	def PlaneLog.create_for_plane(flights)
		# Without merging:
		#flights.map { |flight| PlaneLogEntry.create(flight) }

		result=[]
		entry_flights=[]

		# Iterate over the flights. Flights that can be merged are accumulated
		# in entry_flights.
		prev=nil
		flights.each { |flight|
			if (prev && !flight.can_merge_plane_log_entry?(prev))
				# No further merging
				result << PlaneLogEntry.create_merged(entry_flights)
				entry_flights.clear
			end

			entry_flights << flight
			prev=flight
		}

		result << PlaneLogEntry.create_merged(entry_flights)
	end

	# Create logs for flights of (potentially different) planes
	# Returns a hash from planes to arrays of entries
	def PlaneLog.create_for_flights(flights)
		result={}
		flights.array_hash_by { |flight| flight.plane }.each_pair { |plane, flights|
			result[plane]=PlaneLog.create_for_plane(flights.select { |flight| flight.effective_time }.sort_by { |flight| flight.effective_time })
		}
		result
	end
end

