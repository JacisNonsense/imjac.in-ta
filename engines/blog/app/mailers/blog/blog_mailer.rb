module Blog
  class BlogMailer < ApplicationMailer
    def new_article_email
      @subscription = params[:subscription]
      @articles = params[:articles]
      mail(to: @subscription.email, subject: "I'm Jac.in/ta - New blog posts!")
    end
  end
end
