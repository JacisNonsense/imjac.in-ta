module Blog
  class ApplicationMailer < ActionMailer::Base
    default from: 'blog@imjac.in'
    layout 'blog/mailer'
  end
end

