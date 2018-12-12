Rails.application.routes.draw do
  mount Dev::Engine => "/dev"
  
  mount Blog::Engine => "/"
end
