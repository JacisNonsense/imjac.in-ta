Rails.application.routes.draw do
  mount Blog::Engine => "/ta"
  mount Dev::Engine => "/dev"

  match '/', to: redirect('/ta'), via: :all
end
