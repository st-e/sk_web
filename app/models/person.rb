# encoding: utf-8

class Person < ActiveRecord::Base
	include DateHandling

	# Associations
	has_one :user

	# Validations
	# The club ID must be unique within the club unless it is empty or no club
	# is given.
	validates_uniqueness_of :club_id, :scope => :club, :if => :club_and_club_id_present,
		:message => 'ist in diesem Verein schon vergeben (und nicht leer)'

	validate :medical_validity_valid_or_blank
	
	def medical_validity_valid_or_blank
		errors.add :medical_validity_text, "ist ungültig" if @medical_validity_invalid
	end 
	

	# Human names for attributes
	# .label of form_helper does not use this, but error_messages does
	attr_human_name 'last_name'                  => 'Nachname'
	attr_human_name :first_name                  => 'Vorname'
	attr_human_name :club                        => 'Verein'
	attr_human_name :medical_validity            => 'Medical gültig bis'
	attr_human_name :medical_validity_text       => 'Medical gültig bis'
	attr_human_name :check_medical_validity      => 'Medical prüfen'
	attr_human_name :check_medical_validity_text => 'Medical prüfen'
	attr_human_name :club_id                     => 'Vereins-ID'
	attr_human_name :nickname                    => 'Verein'
	attr_human_name 'comments'                   => 'Bemerkungen'

	# Callbacks
	# Prevent destruction of people that are in use.
	before_destroy :ensure_not_used

	def medical_validity_text
		if @medical_validity_invalid
			@medical_validity_text
		else
			date_formatter(german_format, true).call(self.medical_validity)
		end
	end

	def medical_validity_text=(value)
		if value.blank?
			self.medical_validity=nil
		else
			self.medical_validity=parse_date(value)
		end
	rescue ArgumentError
		@medical_validity_invalid=true
		@medical_validity_text=value
	end

	def full_name(with_nickname=false)
		if with_nickname
			"#{first_name} \"#{last_name}\" #{nickname}"
		else
			"#{first_name} #{last_name}"
		end
	end

	def formal_name
		"#{last_name}, #{first_name}"
	end

	def effective_medical_validity(default, format=german_format, strip_leading_zeros=true)
		if medical_validity
			date_formatter(format, strip_leading_zeros).call(self.medical_validity)
		else
			default
		end
	end

	def destroy
		# Don't allow destruction of people which are in use; this is already
		# handled by the before_destroy callback, but this is really important.
		if used?
			raise "Eine benutzte Person kann nicht gelöscht werden"
		else
			super
		end
	end

	def used?
		User  .exists?(:person_id  =>id)||
		Flight.exists?(:pilot_id   =>id)||
		Flight.exists?(:copilot_id =>id)||
		Flight.exists?(:towpilot_id=>id)
	end
	

	def club_and_club_id_present
		!club.blank? and !club_id.blank?
	end

	class ImportData
		include DateHandling

		# Don't use Person here because it needs to be Marshalled
		class Entry
			include DateHandling

			attr_accessor :last_name, :first_name, :comments, :club_id, :old_club_id, :club, :medical_validity_text, :medical_validity, :check_medical_validity_text, :check_medical_validity
			attr_accessor :id, :error_message

			# Identifies a person, that is, determines the ID of the person in
			# the database that matches this record. Identification works as
			# follows (the first applicable option is used):
			#   - If an old club ID is given, the club ID of the person must
			#     match that club ID. If no person is found, this is an error.
			#     This can be used for changing club IDs.
			#   - If a club ID is given, the club ID of the person must match
			#     that club ID. If no person is found, a new person will be
			#     created. This can be used for changing the name of a person.
			#   - Otherwise, the last name and the first name of the person
			#     must match the given values. If no person is found, a new
			#     person will be created.
			# In any case, the club of a person must match the given club
			# (people with a different club are not considered) and the person
			# must be unique. A non-unique person is an error.
			# If a new person is to be created, the ID is set to 0. On error,
			# the ID is set to nil and error_message is set.
			# Notes:
			#   - If a club ID is given, but not found, identification by name
			#     (which could be used for adding a club ID to a person) is not
			#     attempted because this would pose problems when two people
			#     with the same name (but different club IDs) are in the file,
			#     one of which is already in the database (without club ID)
			#   - It is not possible to add a club ID to a person via import.
			#     This is because for multiple people with the same name, it
			#     would be ambiguous which one should overwrite the person in
			#     the database.
			def identify
				if !@old_club_id.blank?
					# Old club ID given - identify by old club ID
					candidates=Person.all(:conditions => { :club => @club, :club_id => @old_club_id }, :readonly=>true)
					case candidates.size
					when 0 then @id=nil; @error_message="Keine Person mit der angegebenen alten Vereins-ID im Verein \"#{@club}\" gefunden"
					when 1 then @id=candidates[0].id
					else    @id=nil; @error_message="Mehrere Personen mit der angegebenen alten Vereins-ID im Verein \"#{@club}\" gefunden"
					end
				elsif !@club_id.blank?
					# Club ID given - identify by club ID
					candidates=Person.all(:conditions => { :club => @club, :club_id => @club_id }, :readonly=>true)
					case candidates.size
					when 0 then @id=0 # Not found - create new
					when 1 then @id=candidates[0].id
					else    @id=nil; @error_message="Mehrere Personen mit der angegebenen Vereins-ID im Verein \"#{@club}\" gefunden"
					end
				else
					# Neither old nor current club ID given - identify by name
					candidates=Person.all(:conditions => { :club => @club, :last_name => @last_name, :first_name => @first_name }, :readonly=>true)
					case candidates.size
					when 0 then @id=0 # Not found - create new
					when 1 then @id=candidates[0].id
					else    @id=nil; @error_message="Mehrere Personen mit dem angegebenen Namen im Verein \"#{@club}\" gefunden"; return
					end
				end
			end

			def identified?
				!@id.nil?
			end

			def new?
				@id==0
			end

			def changed?
				return false if new?
				return false if !identified?
				
				# Retrieve the person and store its attributes
				person=Person.find(@id, :readonly=>true)
				old_attributes=person.attributes

				# Update the person (don't save it)
				person.attributes=attribute_hash

				# Compare its attributes with the store attributes.
				person.attributes!=old_attributes
			end

			def attribute_hash
				# The attribute hash only includes values that are not nil.
				result={}
				result['first_name'            ]=@first_name             if @first_name
				result['last_name'             ]=@last_name              if @last_name
				result['club'                  ]=@club                   if @club
				result['medical_validity'      ]=@medical_validity       if @medical_validity
				result['check_medical_validity']=@check_medical_validity if @check_medical_validity
				result['club_id'               ]=@club_id                if @club_id
				result['comments'              ]=@comments               if @comments
				result
			end

			# TODO code duplication - same method in Person
			def effective_medical_validity(default, format=german_format, strip_leading_zeros=true)
				if medical_validity
					date_formatter(format, strip_leading_zeros).call(self.medical_validity)
				else
					default
				end
			end
		end

		attr_reader :missing_columns, :entries
		attr_reader :creation_time, :original_filename

		# Creates an ImportData instance from a CSV file. The number and order
		# of the columns is read from the first row in the file, the header
		# row.
		# Values not specified, either because the column is not present in the
		# file (header row) or because the row is shorter than the header row,
		# will be nil. Columns with empty values (this includes the column past
		# a trailing comma at the end of a row) will be returned as "" (so they
		# can be distingushed from values which are not specified).
		def initialize(csv, original_filename, club)
			@creation_time=Time.now
			@original_filename=original_filename

			# Parse the header (an empty file will yield [])
			reader=CSV::Reader.create(csv)
			header_row=reader.shift

			# Build the column index hash
			columns={}
			header_row.each_with_index { |column, index|
				case column.strip
				when /^nachname$/i               then columns[:last_name              ]=index
				when /^vorname$/i                then columns[:first_name             ]=index
				when /^medical gültig bis$/i     then columns[:medical_validity       ]=index
				when /^medical prüfen$/i         then columns[:check_medical_validity ]=index
				when /^bemerkungen$/i            then columns[:comments               ]=index
				when /^vereins-id$/i             then columns[:club_id                ]=index
				when /^vereins-id_alt$/i         then columns[:old_club_id            ]=index
				end
			}

			# Make sure that all required columns are present
			@missing_columns=[]
			@missing_columns << "Nachname" if !columns.has_key? :last_name
			@missing_columns << "Vorname"  if !columns.has_key? :first_name
			return unless @missing_columns.empty?

			# Build the entry list
			@entries=[]
			reader.each { |row|
				next if row.empty? || row==[nil]

				# Empty values in the row are returned as nil by the CSV
				# parser. However, we want them to be "", so we can distinguish
				# them from values not specified at all. We also strip the
				# values at this point.
				row.map! { |value| (value || "").strip }

				# Columns which do not exist in the file will have a column
				# index of nil. We want the values from these columns to read
				# as nil. Columns not present in a row will also be nil.
				def row.[](index)
					return nil if index.nil?
					super(index)
				end

				entry=Entry.new
				# Values for non-existing (nil) columns yields nil (see the
				# monkey patch above).
				entry.last_name              = row[columns[:last_name              ]]
				entry.first_name             = row[columns[:first_name             ]]
				entry.medical_validity_text  = row[columns[:medical_validity       ]]
				begin
					entry.medical_validity       = parse_date(entry.medical_validity_text)
				rescue ArgumentError
					entry.medical_validity       = nil
				end
				entry.check_medical_validity_text  = row[columns[:check_medical_validity ]]
				if entry.check_medical_validity_text.blank?
					entry.check_medical_validity = false
				else
					entry.check_medical_validity = entry.check_medical_validity_text.to_b # nil if not recognized
				end
				entry.comments               = row[columns[:comments               ]]
				entry.club_id                = row[columns[:club_id                ]]
				entry.old_club_id            = row[columns[:old_club_id            ]]
				entry.club=club

				@entries << entry
			}
		end

		def check_errors
			errors=[]

			# Note that there are non-symmetric error relations: for example,
			# two people with the same name, only one of which has as club ID.
			# This is an error for the person without, but not for the one with
			# a club ID. Thus we have check all people against all others, even
			# if we already checked the reverse.
			@entries.each { |entry|
				# First name or last name empty
				errors << { :message=>"Vorname ist leer" , :entries=>[entry] } if entry.first_name.blank?
				errors << { :message=>"Nachname ist leer", :entries=>[entry] } if entry.last_name .blank?
				errors << { :message=>"Ungültiges Medical-Gültigkeitsdatum", :entries=>[entry] } if !(entry.medical_validity || entry.medical_validity_text.blank?)
				errors << { :message=>"Ungültiges Wert für „Medical prüfen“", :entries=>[entry] } if entry.check_medical_validity.nil?

				@entries.each { |other_entry|
					if !other_entry.equal? entry
						# Non-unique club ID
						if !entry.club_id.blank? &&
							entry.club_id == other_entry.club_id
							errors << { :message=>"Doppelte Vereins-ID", :entries=>[entry, other_entry] }
						end

						# Non-unique name without club id
						if entry.club_id.blank? &&
							entry.first_name == other_entry.first_name &&
							entry.last_name  == other_entry.last_name

							errors << { :message=>"Doppelter Name ohne Vereins-ID", :entries=>[entry, other_entry] }
						end
					end
				}
			}

			errors
		end

		def identify_entries
			errors=[]

			entries.each { |entry|
				entry.identify
				errors << { :message=>entry.error_message, :entries=>[entry] } if entry.id.nil?
			}

			errors
		end

		def ok?
			entries.all? { |entry| entry.identified?  }
		end
	end



protected
	def ensure_not_used
		if used?
			errors.add_to_base "Person wird noch benutzt"
			return false # return exactly false
		end
	end
end

