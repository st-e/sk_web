class User < ActiveRecord::Base
	 set_table_name "user" 
	 set_primary_key "username"

	 belongs_to :person, :foreign_key => 'person'
end

