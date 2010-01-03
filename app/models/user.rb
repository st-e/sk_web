class User < ActiveRecord::Base
	 set_table_name "user" 
	 set_primary_key "username"

	 # TODO: will editing get easier if the name is not the same as the foreign key?
	 belongs_to :person, :foreign_key => 'person'
end

