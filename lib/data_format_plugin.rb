# encoding: utf-8

class DataFormatPlugin
	def self.def_field(*names)
		class_eval do 
			names.each do |name|
				define_method(name) do |*args| 
					case args.size
						when 0 then instance_variable_get("@#{name}")
						else    instance_variable_set("@#{name}", *args)
					end
				end
			end
		end
	end

	def_field :title, :author, :version

	@registered_plugins={}
	class << self
		attr_reader :registered_plugins
		private :new
	end

	def self.define(name, &block)
		plugin=new
		plugin.instance_eval(&block)
		DataFormatPlugin.registered_plugins[name]=plugin
	end

	def make_table(flights)
		columns=column_titles.map { |title| { :title=>title } }
		rows=column_values(flights)
		
		{ :columns => columns, :rows => rows, :data => flights }
	end
end

# Load all plugins
#DataFormatPlugin.list=[]
Dir["#{RAILS_ROOT}/lib/plugins/data_format/*.rb"].each { |x| load x }


