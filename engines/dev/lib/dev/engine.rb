module Dev
  class Engine < ::Rails::Engine
    isolate_namespace Dev

    require "rails-fontawesome5"
  end
end
