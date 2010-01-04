class PeopleController < ApplicationController
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
				flash[:notice] = 'Person was successfully created.'
				format.html { redirect_to(@person) }
				#format.xml  { render :xml => @person, :status => :created, :location => @person }
			else
				format.html { render :action => "new" }
				#format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
			end
		end
	end

	def edit
		@person=Person.find(params[:id])
	end

	def update
		@person = Person.find(params[:id])

		respond_to do |format|
			if @person.update_attributes(params[:person])
				flash[:notice] = 'Person was successfully updated.'
				format.html { redirect_to(@person) }
				#format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				#format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
			end
		end
	end

	def destroy
		@person=Person.find(params[:id])

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

		# Retrieve the wrong person
		@wrong_person=Person.find(wrong_person_id)

		# Check if a correct person has been selected
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

		# Check if the correct person has been confirmed
		if !params[:confirm].to_b
			# A "correct" person has been selected, but not confirmed yet

			# Let the user confirm the wrong and correct people
			render 'overwrite_confirm' and return
		end

		# The wrong person has been selected and confirmed.

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

		# Once again for safety
		flash[:error]="Nach dem Überschreiben ist die Person noch in Benutzung" and redirect_to and return if @wrong_person.used?

		# Delete the person
		wrong_person_name=@wrong_person.full_name
		@wrong_person.destroy
		
		flash[:notice]="#{wrong_person_name} wurde durch #{@correct_person.full_name} ersetzt."
		redirect_to :action=>'index'
	end
end

