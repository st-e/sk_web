# encoding: utf-8

require 'erb'
require 'csv'

require_dependency 'yesno'
require_dependency 'version'
require_dependency 'csv_methods'
require_dependency 'date_handling'
require_dependency 'menu'
require_dependency 'system_info'

# TODO cleanup, move to lib

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
    include DateHandling

    # The argument will not be HTML escaped!
    def page_title(title, &block)
        content_for(:title, title)

        if block_given?
            return heading(title, :class=>"page_title", &block)
        else
            return heading(title, :class=>"page_title")
        end
    end

    # Creates a heading (<h?>...</h?>) tag at the current level. The current
    # level is stored in the variable @heading_level. A heading level of x
    # means that the next heading tag will be <hx>.
    # This method can be used in two ways:
    # 1. without block - generates a heading at the current level:
    #   <%= heading h("Title") %>
    # 2. with block:
    #   <% heading h("Title") do %>
    #     <% heading h("Subtitle 1") do %>
    #       <div>Contents</div>
    #     <% end %>
    #     <%= heading h("Subtitle 2") do %>
    #       <div>Contents</div>
    #     <% end %>
    #   <% end %>
    # The contents will not be escaped.
    # In any case, options can be given, for example:
    #   heading "Title", :class=>"page_title"
    def heading(title, options=nil, &block)
        # The first usable heading level (h1 is taken by the application
        # layout, which does not use this method because it is rendered *after*
        # the page).
        @heading_level=2 if !defined? @heading_level

        retval= content_tag("h#{@heading_level}", title, options)
        if block_given?
            # Block mode
            @heading_level += 1
            retval << capture(&block)
            @heading_level -= 1
        end
        return retval
    end
end

