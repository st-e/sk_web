# encoding: utf-8

class SystemInfo
	@data={}

	def self.username
		@data['username'] ||= shell('whoami')
		# id -u -n
	end

	def self.groupname
		@data['groupname'] ||= shell('id -g -n')
	end

	def self.hostname
		@data['hostname'] ||= shell('hostname')
	end

	def self.id
		@data['id'] ||= shell('id')
	end

	def self.groupnames
		@data['groupnames'] ||= shell('id -G -n')
	end

	private

	def self.shell(cmd)
		result=`#{cmd}`

		return nil if !result
		return nil if $?!=0
		result.chomp
	end


end

