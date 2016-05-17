# encoding: utf-8

module PageInfoHelper
    def page_first(collection)
        collection.offset + 1
    end

    def page_last(collection)
        collection.offset + collection.length
    end

    def singular_name(collection)
        return "Eintrag" if collection.empty?
        collection.first.class.name.underscore.sub('_', ' ')
    end

    def page_info(collection, singular=nil, plural=nil, options = {})
        singular ||= singular_name
        plural   ||= singular.pluralize

        return content_tag(:p) {
            if collection.total_pages < 2
                case collection.size
                    when 0
                        concat "Keine #{h plural}"
                    when 1
                        concat content_tag(:b, 1)
                        concat " #{h singular}"
                    else
                        concat content_tag(:b, "#{size}")
                        concat " #{h plural}"
                end
            else
                concat "#{h plural.capitalize} "
                concat content_tag(:b, page_first(collection))
                concat " bis "
                concat content_tag(:b, page_last(collection))
                concat " von "
                concat content_tag(:b, collection.total_entries)
            end
        }
    end
end #module PageInfoHelper
