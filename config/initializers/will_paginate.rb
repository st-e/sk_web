require 'will_paginate'
require 'will_paginate_extensions'

WillPaginate::ViewHelpers.pagination_options[:previous_label] = '&laquo; Zurück'
WillPaginate::ViewHelpers.pagination_options[:next_label] = 'Vor &raquo;'

