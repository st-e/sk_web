# encoding: utf-8

require_dependency 'attempt'

class PeopleController < ApplicationController
	require_permission :club_admin, :index, :show, :new, :create, :edit, :update, :destroy, :overwrite, :import, :export
	require_permission :sk_admin, :delete_unused

	class ImportError <Exception
	end

	def index
		attempt do
			@people = Person.paginate :page => params[:page], :per_page => 50, :order => 'last_name, first_name', :readonly=>true
			params[:page]=1 and redo if (!@people.empty? and @people.out_of_bounds?)
		end

		respond_to do |format|
			format.html
			#format.xml  { render :xml => @people }
		end
	end

	def show
		@person=Person.find(params[:id], :readonly=>true)

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
				flash[:notice] = "Die Person #{@person.full_name} wurde angelegt."
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
		@person=Person.find(params[:id], :readonly=>true)
	end

	def update
		@person = Person.find(params[:id])

		respond_to do |format|
			if @person.update_attributes(params[:person])
				flash[:notice] = "Die Person #{@person.full_name} wurde aktualisiert."
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
			full_name=@person.full_name
			if @person.destroy
				flash[:notice] = "Die Person #{full_name} wurde gelöscht."
			else
				flash[:error] = "Beim Löschen ist ein Fehler aufgetreten."
			end
		end

		respond_to do |format|
			format.html { redirect_to(people_url) }
			format.xml  { head :ok }
		end
	end

	def delete_unused
		num_deleted=0
		Person.all.each { |person|
			if !person.used?
				person.destroy
				num_deleted += 1
			end
		}

		flash[:notice]=case num_deleted
		when 0 then "Es wurden keine Personen gelöscht."
		when 1 then "1 Person wurde gelöscht."
		else    "#{num_deleted} Personen wurden gelöscht."
		end

		redirect_to :action=>'index'
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
			attempt do
				@people = Person.paginate(:page => params[:page], :per_page => 50, :order => 'last_name, first_name', :readonly=>true).reject { |person| person.id==@wrong_person.id }
				params[:page]=1 and redo if (!@people.empty? and @people.out_of_bounds?)
			end

			render 'overwrite_select' and return
		end

		# Retrieve the correct person
		@correct_person=Person.find(correct_person_id, :readonly=>true)

		# 2. confirm the operation
		if !params[:confirm].to_b
			# A "correct" person has been selected, but not confirmed yet

			# Let the user confirm the wrong and correct people
			render 'overwrite_confirm' and return
		end

		# 3. perform the operation

		# Update users and flights
		User  .all(:conditions => { :person_id  => wrong_person_id }).each { |user|   user.person_id    = correct_person_id; user  .save }
		Flight.all(:conditions => { :pilot_id   => wrong_person_id }).each { |flight| flight.pilot_id   = correct_person_id; flight.save }
		Flight.all(:conditions => { :copilot_id => wrong_person_id }).each { |flight| flight.copilot_id = correct_person_id; flight.save }
		Flight.all(:conditions => { :towpilot_id=> wrong_person_id }).each { |flight| flight.towpilot_id= correct_person_id; flight.save }

		# Check that the person has no flights or users any more
		flash[:error]="Fehler: Nach dem Überschreiben der Person existiert noch ein Benutzer, der auf die Person verweist." and redirect_to and return if User  .exists? :person_id   =>wrong_person_id
		flash[:error]="Fehler: Nach dem Überschreiben der Person existiert noch ein Flug, der auf die Person verweist."     and redirect_to and return if Flight.exists? :pilot_id    =>wrong_person_id
		flash[:error]="Fehler: Nach dem Überschreiben der Person existiert noch ein Flug, der auf die Person verweist."     and redirect_to and return if Flight.exists? :copilot_id  =>wrong_person_id
		flash[:error]="Fehler: Nach dem Überschreiben der Person existiert noch ein Flug, der auf die Person verweist."     and redirect_to and return if Flight.exists? :towpilot_id =>wrong_person_id

		# Once again for safety, as this is really important
		flash[:error]="Fehler: Nach dem Überschreiben ist die Person noch in Benutzung." and redirect_to and return if @wrong_person.used?

		# Delete the person
		wrong_person_name=@wrong_person.full_name
		@wrong_person.destroy
		
		flash[:notice]="#{wrong_person_name} wurde durch #{@correct_person.full_name} ersetzt."
		redirect_to :action=>'index'
	end

	def import
		# cancel |file upload |datafile |confirm ||action                         |render                    |description
		# -------+------------+---------+--------++-------------------------------+--------------------------+-----------------
		# yes    |-           |-        |-       ||delete                         |redirect_to               |0: cancel
		# no     |no          |no       |-       ||select                         |import_select             |1: select
		# no     |yes         |-        |-       ||delete, check, identify, store |redirect_to/import_errors |2: upload+analyze (no store on error)
		# no     |no          |yes      |no      ||load, review                   |import_review             |3: review
		# no     |no          |yes      |yes     ||load, perform, delete          |redirect_to index         |4: perform
		#
		# Import data is only stored when there are no errors.

		file             =params[:file   ]
		cancel           =params[:cancel ]
		confirm          =params[:confirm].to_b
		have_import_data =have_import_data?

		# 0: Cancel
		if cancel
			cleanup_import_data
			redirect_to
			return
		end

		# 1. select a file
		if !have_import_data && !file
			@club=current_user.club.strip
			render 'import_select'
			return
		end

		# 2. file upload - analyze+store (don't store on error)
		if file
			# Clean up any stored import data, it's overridden by the new file
			cleanup_import_data
			
			# Analyze the uploaded file
			csv=file.read
			@club=params['club']
			@import_data=Person::ImportData.new(csv, @filename, @club)

			# Check for file (formal) errors
			render_error h "Die folgenden Spalten fehlen in der CSV-Datei: #{@import_data.missing_columns.join(', ')}" and return if !@import_data.missing_columns.empty?
			render_error h "Die CSV-Datei enthält keine Personendatensätze." and return if @import_data.entries.empty?

			# Check for data errors
			@errors=@import_data.check_errors
			render 'import_errors' and return if !@errors.empty?

			# Find the IDs of the people in the database
			@errors=@import_data.identify_entries
			render 'import_errors' and return if !@errors.empty?

			# The import data is OK, store it and redirect
			write_import_data @import_data
			redirect_to
			return
		end

		# 3. review
		if !confirm
			# Read the stored import data
			@import_data=read_import_data
			@import_data_filename=import_data_filename
			render 'import_review'
			return
		end

		# 4. perform
		if confirm
			# Read the stored import data
			@import_data=read_import_data

			# If the filename changed, we have to reconfirm (go back to 3)
			if import_data_filename!=params[:import_data_filename]
				flash[:error]="Seit diese Seite abgerufen wurde, wurde eine neue Datei hochgelanden. Bitte die Daten nochmals überprüfen."
				redirect_to
				return
			end

			# Actually perform
			num_created=0
			num_changed=0
			num_unchanged=0

			errors=[]
			begin
				Person.transaction do
					@import_data.entries.each { |entry|
						if entry.new?
							person=Person.new(entry.attribute_hash)

							if person.save
								num_created+=1
							else
								errors << person
							end
						else
							person=Person.find(entry.id)
							old_attributes=person.attributes

							person.attributes=entry.attribute_hash

							if person.attributes==old_attributes
								num_unchanged+=1
							else
								if person.save
									num_changed+=1
								else
									errors << person
								end
							end
						end
					}

					raise ImportError if !errors.empty?
					cleanup_import_data
				end
			rescue ImportError
			end

			if errors.empty?
				flash[:notice]="Es wurden #{num_created} Personen angelegt, #{num_changed} aktualisiert und #{num_unchanged} nicht geändert."
			else
				flash[:error]="#{errors.size} Fehler beim Importieren"
			end

			redirect_to :action=>'index'
			return
		end

		# Fallthrough, should not happen
		raise "Unbehandelter Fall in PeopleController::import"
		redirect_to
	end

	def export
		if !params[:commit]
			@club=current_user.club.strip
			render 'export_select'
			return
		end

		if params[:club].blank?
			@people=Person.all
		else
			@people=Person.find_all_by_club(params[:club].strip)
		end

		@table=make_table(@people)

		# Hack, because otherwise, the HTML partial will be rendered
		params[:format]='csv'

		render 'people.csv'
		set_filename "personen_#{Date.today}.csv"
	end

protected
	def import_data_filename
		session[:people_import_data_filename]
	end

	def import_data_filename=(filename)
		session[:people_import_data_filename]=filename
	end

	def write_import_data(import_data)
		raise "Vor dem Speichern sind noch fehlerhafte Personen vorhanden" if !import_data.ok?
		filename=write_temporary_file('sk_web-people-import_data') { |file|
			Marshal.dump import_data, file
		}
		session[:people_import_data_filename]=filename
	end

	def have_import_data?
		filename=import_data_filename
		return false if !filename
		return true if File.exist? filename
		session[:people_import_data_filename]=nil
		false
	end
	
	def read_import_data
		Person # load Person so we can unmarshal Person::ImportData
		filename=import_data_filename
		import_data=nil
		File.open(filename) { |file|
			import_data=Marshal.load file
		}
		raise "Nach dem Laden sind noch fehlerhafte Personen vorhanden" if !import_data.ok?
		import_data
	end

	def cleanup_import_data
		filename=import_data_filename
		if filename
			if File.exist? filename
				File.delete filename
			end
			import_data_filename=nil
		end
	end

	def make_table(people)
		columns = [
			{ :title => 'Nachname'           },
			{ :title => 'Vorname'            },
			{ :title => 'Verein'             },
			{ :title => 'Medical gültig bis' },
			{ :title => 'Medical prüfen'     },
			{ :title => 'Bemerkungen'        },
			{ :title => 'Vereins-ID'         }
		]

		rows=people.map { |person| [
			person.last_name,
			person.first_name,
			person.club,
			person.effective_medical_validity(nil, iso_format, false),
			(person.check_medical_validity || false), # Make sure we get "false" even for nil
			person.comments,
			person.club_id
		] }

		{ :columns => columns, :rows => rows, :data => people }
	end
end

