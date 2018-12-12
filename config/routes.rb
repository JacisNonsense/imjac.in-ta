Rails.application.routes.draw do
  constraints subdomain: "dev" do
    match '(*_)' => "subdomain#redirect", via: :all
  end

  mount Blog::Engine => "/ta"
  mount Dev::Engine => "/dev"

  match '/', to: redirect('/ta'), via: :all
end
