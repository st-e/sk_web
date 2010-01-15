class Person < ActiveRecord::Base
	# Table settings
	set_table_name "person_temp" 
	 
	# Associations
	has_one :user, :foreign_key => 'person'

	# Attribute aliases
	alias_attribute :last_name , :nachname
	alias_attribute :first_name, :vorname
	alias_attribute :club      , :verein
	alias_attribute :club_id   , :vereins_id
	alias_attribute :comments  , :bemerkung

	# Validations
	# The club ID must be unique within the club unless it is empty or no club
	# is given.
	validates_uniqueness_of :vereins_id, :scope => :verein, :if => :club_and_club_id_present,
		:message => 'ist in diesem Verein schon vergeben (und nicht leer)'

	# Human names for attributes
	attr_human_name :verein     => 'Verein'
	attr_human_name :vereins_id => 'Vereins-ID'

	# Callbacks
	# Prevent destruction of people that are in use.
	before_destroy :ensure_not_used


	def full_name(with_nickname=false)
		if with_nickname
			"#{vorname} \"#{spitzname}\" #{nachname}"
		else
			"#{vorname} #{nachname}"
		end
	end

	def formal_name
		"#{nachname}, #{vorname}"
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
		User  .exists?(:person    =>id)||
		Flight.exists?(:pilot     =>id)||
		Flight.exists?(:begleiter =>id)||
		Flight.exists?(:towpilot  =>id)
	end
	

	def club_and_club_id_present
		!club.blank? and !club_id.blank?
	end

	class ImportData
		# Don't use Person here because it needs to be Marshalled
		class Entry
			attr_accessor :last_name, :first_name, :comments, :club_id, :old_club_id, :club
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
				# TODO generally, is there a difference between nil (not
				# present in the file) and blank (empty field in the file)?
				# No, because "" means "not present for that person"?

				if !@old_club_id.blank?
					# Identify by old club ID
					candidates=Person.all(:conditions => { :verein => @club, :vereins_id => @old_club_id })
					case candidates.size
					when 0: @id=nil; @error_message="Keine Person mit der angegebenen alten Vereins-ID im Verein \"#{@club}\" gefunden"
					when 1: @id=candidates[0].id
					else    @id=nil; @error_message="Mehrere Personen mit der angegebenen alten Vereins-ID im Verein \"#{@club}\" gefunden"
					end
				elsif !@club_id.blank?
					# Identify by club ID
					candidates=Person.all(:conditions => { :verein => @club, :vereins_id => @club_id })
					case candidates.size
					when 0: @id=0 # Not found - create new
					when 1: @id=candidates[0].id
					else    @id=nil; @error_message="Mehrere Personen mit der angegebenen Vereins-ID im Verein \"#{@club}\" gefunden"
					end
				else
					# Identify by name
					# club_id must also be empty (to remove a club ID, we have
					# to select the person by old club ID)
					# TODO what about NULL club ID in database?
					# TODO does the club ID really have to be empty?
					candidates=Person.all(:conditions => { :verein => @club, :vereins_id => "", :nachname => @last_name, :vorname => @first_name })
					case candidates.size
					when 0: @id=0 # Not found - create new
					when 1: @id=candidates[0].id
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
				
				person=Person.find(@id)
				old_attributes=person.attributes

				person.attributes=attribute_hash

				person.attributes!=old_attributes
			end

			def attribute_hash
				result={}
				result['vorname'   ]=@first_name if @first_name
				result['nachname'  ]=@last_name  if @last_name
				result['verein'    ]=@club       if @club
				result['vereins_id']=@club_id    if @club_id
				result['bemerkung' ]=@comments   if @comments
				result
			end
		end

		attr_reader :missing_columns, :entries
		attr_reader :creation_time, :original_filename

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
				when /^nachname$/i      : columns[:last_name  ]=index
				when /^vorname$/i       : columns[:first_name ]=index
				when /^bemerkungen$/i   : columns[:comments   ]=index
				when /^vereins-id$/i    : columns[:club_id    ]=index
				when /^vereins-id_alt$/i: columns[:old_club_id]=index
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

				def row.[](index)
					(index.nil?)? nil : super(index)
				end

				entry=Entry.new

				entry.last_name   =(row[columns[:last_name  ]] || "").strip
				entry.first_name  =(row[columns[:first_name ]] || "").strip
				entry.comments    =(row[columns[:comments   ]] || "").strip
				entry.club_id     =(row[columns[:club_id    ]] || "").strip
				entry.old_club_id =(row[columns[:old_club_id]] || "").strip
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
			# TODO when an old club ID is given, a club ID must also be given
			@entries.each { |entry|
				# First name or last name empty
				errors << { :message=>"Vorname ist leer" , :entries=>[entry] } if entry.first_name.blank?
				errors << { :message=>"Nachname ist leer", :entries=>[entry] } if entry.last_name .blank?

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
			errors.add_to_base "Person wird nocht benutzt"
			return false # return exactly false
		end
	end
end

