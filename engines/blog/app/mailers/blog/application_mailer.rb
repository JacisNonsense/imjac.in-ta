module Blog
  class ApplicationMailer < ActionMailer::Base
    default from: "I'm Jac.in/ta <blog@imjac.in>"
    layout 'blog/mailer'
  end
end

