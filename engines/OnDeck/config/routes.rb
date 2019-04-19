OnDeck::Engine.routes.draw do

  root :to => 'home#index'

  get 'api/recommendations' => 'api#recommendations', defaults: { format: 'json' }
end
