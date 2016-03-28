# encoding: utf-8

require 'rexml/document'
require 'mysql2'

class Version
	include Singleton

	attr_reader :name, :base_version, :version, :revision
	attr_reader :ruby, :rails, :mysql_client, :mysql_server, :mysql_server_short, :prawn
	attr_reader :database, :server, :effective_server, :host, :database_user

	attr_reader :short_version_string
	attr_reader :version_string
	attr_reader :database_string
	attr_reader :short_database_string

	def initialize
		@name="sk_web"
		@base_version="2.1.1"
		@revision=svn_revision!
		@version=("#{@base_version} (rev. #{@revision})" if @revision) || @base_version

		@ruby=RUBY_VERSION
		@rails=Rails::VERSION::STRING

		#There seems to be no equivalent in MySql2 other then MySql2::Client.info
		#which would require an instance of Client.
		#Disabled because I did not find a better solution (CK, 2014-07-26)
		#@mysql_client=Mysql.client_version.to_s.sub(/^(.)(..)(..)/, '\\1.\\2.\\3')
		@mysql_server=ActiveRecord::Base.connection.show_variable('version')
		@mysql_server_short=@mysql_server.gsub(/-.*/, '')
		@prawn=Prawn::VERSION

		config=Rails::Configuration.new
		@host=`hostname`.strip
		@database=config.database_configuration[RAILS_ENV]["database"] 
		@server=config.database_configuration[RAILS_ENV]["host"] 
		@database_user=config.database_configuration[RAILS_ENV]["username"] 
		@effective_server=(@host if is_localhost?(server)) or @server

		@version_string="#{@name} Version #{@version}/Ruby #{@ruby}/Rails #{@rails}/MySQL #{@mysql_server_short}"

		@database_string="#{@database_user}@#{@effective_server}:#{@database}"
		@short_database_string="#{@database}@#{@effective_server}"
	end

	protected

	def is_localhost?(server)
		server=="localhost" || server=="127.0.0.1"
	end

	def svn_revision!
		return nil if !File.directory? ".svn"

		svn_info=`svn info --xml`

		# No svn revision if either this is not a working copy or svn is not
		# installed.
		return nil if !$? # Seems like this can happen on windows
		return nil if $?.exitstatus!=0
		return nil if svn_info.blank?

		svn_xml=REXML::Document.new(svn_info)

		info=svn_xml.elements['info']
		return nil if !info

		entry=info.elements['entry']
		return nil if !entry

		entry.attributes['revision']
	end
end

