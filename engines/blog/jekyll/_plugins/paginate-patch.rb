# Paginate monkey patch to override pagination behaviour
# Adds an option for a magic pagination subdir: __ALL__, that shows all posts
# regardless of subdir
require 'jekyll-paginate'
require 'jekyll-paginate-multiple'

module Jekyll
  module Paginate
    module Multiple
      class MultiplePagination
        def posts_for_sub_dir(site, sub_dir)
          site.site_payload['site']['posts'].reject{ |post| (!post_is_in_sub_dir(post, sub_dir) && sub_dir != '__ALL__') || post['hidden'] }
        end
      end
    end
  end
end
