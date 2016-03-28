# encoding: utf-8

class Menu
	# The text to display in the menu
	attr_accessor :text
	
	# The link target (or nil for no link)
	attr_accessor :target
	
	# The submenu entries if this menu entry has a submenu
	attr_accessor :entries

	# The ActionView used for rendering this menu
	attr_accessor :view

	attr_accessor :visible

	# Creates a new menu entry with given text, link target and entries.
	# Menu.create et. al are more useful.
	def initialize(text=nil, target=nil, entries=[])
		@text=text
		@target=target
		@entries=entries

		@visible=true
	end

	# Creates a menu, for use as top level menu, with a given view. The view can
	# be used to create links. If a block is given, the newly created menu is
	# passed to the block before returning it.
	def Menu.create(view=nil)
		# Create the menu and set its view
		menu=Menu.new
		menu.view=view

		yield menu if block_given?
		menu
	end

	# Creates a child of thie menu entry. target accepts a String containing a
	# link or the same arguments as url_for, when a view is set. The menu entry
	# has the same view as its parent. If a block is given, the newly created menu
	# entry is yielded to the block before returning it.
	def entry(text, target=nil, visible=true)
		if @view && target && !target.instance_of?(String)
			target=view.url_for target
		end

		entry=Menu.new(text, target)
		entry.view=@view
		entry.visible=visible

		entries << entry
		yield entry if block_given?
		entry
	end

	def entry_if(visible, text, target)
		entry(text, target, visible)
	end
end

