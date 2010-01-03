class User < ActiveRecord::Base
	 set_table_name "user" 
	 set_primary_key "username"

	 # It's called associated_person rather than person because the attribute
	 # name should be different from the foreign key. Otherwise, we could not
	 # distinguish between accesses to the attribute and to the key.
	 belongs_to :associated_person, :class_name => "Person", :foreign_key => 'person'
end

