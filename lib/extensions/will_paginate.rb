# encoding: utf-8

module WillPaginate
    class ButtonRenderer < ::WillPaginate::ActionView::LinkRenderer

        #Creates the numbered buttons for each page & replaces standard
        #will_paginate output by submit_tags 
        def page_number(page)
            unless page == current_page
                @template.submit_tag(page, {:name=> "page_#{page}", :rel => rel_value(page)})
            else
                @template.submit_tag(page, {:name=> "page_#{page}", :class => "current", :disabled => true})
            end
        end

        #Creates the previous or next links in user edit dialog. Replaces the
        # default will_paginate html by submit tags
        def previous_or_next_page(page, text, classname)
            if page
                #active prev/next button
                @template.submit_tag(text.html_safe, {:name=> "page_#{page}", :class => classname})
            else
                #disabled prev/next button
                @template.submit_tag(text.html_safe, {:name=> "disabled", :disabled => true, :class => classname + " disabled"})
            end
        end
    end #class ButtonRenderer
end #module WillPaginate

# Moved to locale settings in config/locales
#WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&laquo; Zurück'
#WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Vor &raquo;'

