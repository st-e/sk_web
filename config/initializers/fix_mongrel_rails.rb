# Improved from fix by Matthew Denner, https://rails.lighthouseapp.com/projects/8994/tickets/4690-mongrel-doesnt-work-with-rails-238

# Fixes cookie problems with mongrel_rails and Mongrel 2.3.8

begin
	mongrel_available=Gem.available?('mongrel', Gem::Requirement.new('~>1.1.5'))
rescue ArgumentError
	mongrel_available=Gem.available?('mongrel', '~>1.1.5')
end

class Mongrel::CGIWrapper
	def header_with_rails_fix(options = 'text/html')
		@head['cookie'] = options.delete('cookie').flatten.map { |v| v.sub(/^\n/,'') } if options.class != String and options['cookie']
		header_without_rails_fix(options)
	end
	alias_method_chain(:header, :rails_fix)
end if Rails.version == '2.3.8' and mongrel_available and self.class.const_defined?(:Mongrel)

