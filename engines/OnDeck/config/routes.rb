OnDeck::Engine.routes.draw do

  root :to => 'home#index'

  get 'api/recommendations' => 'api#recommendations', defaults: { format: 'json' }

  get 'admin' => 'admin#index'
  get 'admin/job/updatepps' => 'admin#job_updatepps'
  get 'admin/job/updategds' => 'admin#job_updategds'
  get 'admin/job/updaterecs' => 'admin#job_updaterecommendations'

end
