OnDeck::Engine.routes.draw do

  root :to => 'home#index'

  get 'admin' => 'admin#index'
  get 'admin/job/updatepps' => 'admin#job_updatepps'
  get 'admin/job/updategds' => 'admin#job_updategds'

end
