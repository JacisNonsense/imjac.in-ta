require 'yaml'
require 'kramdown'
require 'jekyll/document.rb'

module Blog
  class UpdateArticlesListJob < ApplicationJob
    queue_as :default

    # From jekyll/document.rb
    YAML_FRONT_MATTER_REGEXP = %r!\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)!m.freeze

    def perform(*args)
      dir = Blog::Engine.root.join("jekyll/_posts")
      has_new_articles = false
      Dir.glob("#{dir}/**/*").select { |x| File.file?(x) }.each do |post|
        relative = Pathname.new(post).relative_path_from(Pathname.new(dir)).to_s
        blog = File.dirname(relative)

        content = File.read(post)
        if content =~ YAML_FRONT_MATTER_REGEXP
          content = $POSTMATCH
          yml = Regexp.last_match(1)
          yml_data = YAML::load(yml)

          # From jekyll/excerpt.rb
          head, _, tail = content.to_s.partition('<!-- excerpt -->')
          yml_data['excerpt'] = tail.empty? ? head : head.to_s.dup << "\n\n" << tail.scan(%r!^ {0,3}\[[^\]]+\]:.+$!).join("\n")

          if create_or_update_article(relative, blog, yml_data)
            has_new_articles = true
          end
        end
      end

      # New articles exist - perform a mailing list job!
      if has_new_articles
        SendMailingListJob.perform_later
      end
    end

    def create_or_update_article path, blog, data
      article = Article.find_or_initialize_by(file: path)
      article.blog = blog
      article.title = data['title']
      article.author = data['author']
      article.categories = data['categories']
      article.header_img = data['header-img']
      article.publish_time = data['date']
      sanitized_ex = ActionView::Base.full_sanitizer.sanitize(data['excerpt']).strip
      article.excerpt = Kramdown::Document.new(sanitized_ex).to_html
      is_new = article.new_record?
      article.save
      is_new
    end
  end
end
