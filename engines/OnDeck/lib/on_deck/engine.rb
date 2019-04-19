module OnDeck
  class Engine < ::Rails::Engine
    isolate_namespace OnDeck

    require 'bootstrap'
    require 'rails-fontawesome5'
  end
end
