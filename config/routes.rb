Rails.application.routes.draw do
  mount Blog::Engine => "/"
  mount Dev::Engine => "/dev"
end
