class PeopleController < ApplicationController
	require_permission :club_admin, :index, :show, :new, :create, :edit, :update, :destroy, :overwrite, :import

	def index
		@people=Person.all(:order => "nachname, vorname")

		respond_to do |format|
			format.html
			#format.xml  { render :xml => @people }
		end
	end

	def show
		@person=Person.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			#format.xml  { render :xml => @person }
		end
	end

	def new
		@person = Person.new

		respond_to do |format|
			format.html # new.html.erb
			#format.xml  { render :xml => @person }
		end
	end

	def create
		@person=Person.new(params[:person])

		respond_to do |format|
			if @person.save
				# TODO back to origin
				flash[:notice] = 'Person wurde angelegt'
				format.html { redirect_to(@person) }
				#format.xml  { render :xml => @person, :status => :created, :location => @person }
			else
				format.html { render :action => "new" }
				#format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
			end
		end
	end

	def edit
		store_origin
		@person=Person.find(params[:id])
	end

	def update
		@person = Person.find(params[:id])

		respond_to do |format|
			if @person.update_attributes(params[:person])
				flash[:notice] = 'Person was successfully updated.'
				format.html { redirect_to_origin(default=@person) }
				#format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				#format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
			end
		end
	end

	def destroy
		@person=Person.find(params[:id])

		# We still have to use a flash message despite the before_destroy
		# callback because the person's errors are not displayed anywhere.
		if @person.used?
			flash[:error]="Die Person #{@person.full_name} kann nicht gelöscht werden, da sie in Benutzung ist."
		else
			@person.destroy
		end

		respond_to do |format|
			format.html { redirect_to(people_url) }
			format.xml  { head :ok }
		end
	end

	def overwrite
		wrong_person_id=   params[:id]
		correct_person_id= params[:correct_person_id]

		# Retrieve the "wrong" person
		@wrong_person=Person.find(wrong_person_id)

		# 1. select a "correct" person
		if !correct_person_id
			# No "correct" person is selected yet

			# If we came here by POST, redirect to GET (e. g. "reselect" button)
			redirect_to and return if request.method==:post

			# Let the user select a person
			@people=Person.all.reject { |person| person.id==@wrong_person.id }
			render 'overwrite_select' and return
		end

		# Retrieve the correct person
		@correct_person=Person.find(correct_person_id)

		# 2. confirm the operation
		if !params[:confirm].to_b
			# A "correct" person has been selected, but not confirmed yet

			# Let the user confirm the wrong and correct people
			render 'overwrite_confirm' and return
		end

		# 3. perform the operation

		# Update users and flights
		User  .all(:conditions => { :person     => wrong_person_id }).each { |user|   user.person=      correct_person_id; user  .save }
		Flight.all(:conditions => { :pilot      => wrong_person_id }).each { |flight| flight.pilot=     correct_person_id; flight.save }
		Flight.all(:conditions => { :begleiter  => wrong_person_id }).each { |flight| flight.begleiter= correct_person_id; flight.save }
		Flight.all(:conditions => { :towpilot   => wrong_person_id }).each { |flight| flight.towpilot=  correct_person_id; flight.save }

		# Check that the person has no flights or users any more
		flash[:error]="Nach dem Überschreiben existiert noch ein Benutzer, der auf die Person verweist" and redirect_to and return if User  .exists? :person    =>wrong_person_id
		flash[:error]="Nach dem Überschreiben existiert noch ein Flug, der auf die Person verweist"     and redirect_to and return if Flight.exists? :pilot     =>wrong_person_id
		flash[:error]="Nach dem Überschreiben existiert noch ein Flug, der auf die Person verweist"     and redirect_to and return if Flight.exists? :begleiter =>wrong_person_id
		flash[:error]="Nach dem Überschreiben existiert noch ein Flug, der auf die Person verweist"     and redirect_to and return if Flight.exists? :towpilot  =>wrong_person_id

		# Once again for safety, as this is really important
		flash[:error]="Nach dem Überschreiben ist die Person noch in Benutzung" and redirect_to and return if @wrong_person.used?

		# Delete the person
		wrong_person_name=@wrong_person.full_name
		@wrong_person.destroy
		
		flash[:notice]="#{wrong_person_name} wurde durch #{@correct_person.full_name} ersetzt."
		redirect_to :action=>'index'
	end

	def import
		file=params[:file]

		# 1. upload a file
		if !file
			@club=current_user.club.strip
			render 'import_select' and return
		end

		# 2. examine the file and store the data
		# file.read, file.original_filename
		# File.open("/tmp/xxx", "w") { |tempfile| tempfile.write(@file.read) }



		# TODO:
		#   - format of csv
		#   - temporarily store the file
		#   - fields: Nachname, Vorname, Vereins-ID, [Bemerkungen], Vereins-ID_alt

		# Steps:
		#   - create people from CSV file (make sure they cannot be saved - or
		#     use different class)
		#   - message if file erroneous
		#   - message if no people in file
		#	- db.import_check (persons, messages);
		#     - Single people: first name and last name not empty
		#     - Pairs: non-unique club ID, non-unique name w/o club id
		#     - Don't start at p1 here because there may be error relations
		#       which are not symmetric: for example, two persons with the same
		#       name only one of which has a club ID. This is an error for the
		#       person without, but not for the one with club ID.
		#	- db.import_identify (persons, messages);
		#     - find the IDs of the people
		#   - fatal messages => error
		#   - display (non-fatal) messages to user
		#   - "Die folgenden Personen wurden aus #{filename} gelesen. Bitte überprüfen:"
		#   - buttons "OK", "Zurück"
		#   - write the people to the database
		#   - display "n people imported" message

		# Import messages (fatal=true):
		# imt_first_name_missing,
		# imt_last_name_missing,
		# imt_duplicate_club_id,
		# imt_duplicate_name_without_club_id,
		# imt_club_id_not_found,
		# imt_club_id_old_not_found,
		# imt_club_id_not_unique,
		# imt_multiple_own_persons_name,
		# imt_multiple_own_editable_persons_name,
		# imt_multiple_editable_persons_name,
		# imt_club_mismatch (false)

		render :text => "filename: #{file.original_filename}, contents: #{file.read}"
		#File.open(Rails.root.join('public', 'uploads',
		#						  uploaded_io.original_filename), 'w') do
		#	|file| file.write(uploaded_io.read)  end 
	end
end

