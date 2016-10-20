# encoding: utf-8

module TableForHelper

    def table_for(array, options={}, &block)
        raise "table_for does not allow nested tables" unless @table_for_array.nil?
        @table_for_array= array
        @table_for_tag= :td

        cls="list"
        cls << " nobreak" if options[:nobreak]
        retval=content_tag(:table, capture(&block), :class => cls)
        @table_for_array= nil
        return retval
    end

    def header_row(options={}, &block)
        @table_for_tag= :th
        cls= "header"
        cls << " nobreak" if options[:nobreak]
        concat content_tag(:tr, capture(&block), :class => cls)
        return nil
    end

    def body_row(options={}, &block)
        @table_for_tag= :td
        cls= "data"
        cls << " nobreak" if options[:nobreak]
        concat content_tag(:tr, capture(&block), :class => cls)
        return nil
    end

    def body(options={}, &block)
        @table_for_tag= :td
        alternate=0 #switches between 1 and 0
        @table_for_array.each { |element|
            cls="data#{alternate}"
            cls << " nobreak" if options[:nobreak]
            alternate= 1-alternate
            concat content_tag(:tr, capture(element, &block), :class => cls)
        }
    end

    def cell(contents, options={})
        if contents.is_a? Array
            contents.for_each { |element| cell(element, options) }
        else
            concat content_tag(@table_for_tag, contents, options)
        end
    end

    def text(contents, options={})
        if contents.is_a? Array
            cell(contents.map { |element| h element }, options)
        else
            cell(h(contents), options)
        end
        return nil
    end

    def hidden(options={})
        opt= options.dup
        opt[:style]= "visibility:hidden; #{options[:style]}"
        cell("", opt)
        return nil
    end

end #TableForHelper
