Blog::Engine.routes.draw do
  match '/', to: redirect('/ta'), via: :all
end
