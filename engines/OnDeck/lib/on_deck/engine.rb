module OnDeck
  class Engine < ::Rails::Engine
    isolate_namespace OnDeck

    require 'bootstrap'
    require 'rails-fontawesome5'
    require 'react-rails'
    require 'sidekiq-scheduler'

    initializer "sidekiq_sched" do
      Sidekiq::Scheduler.enabled = true
      Sidekiq::Scheduler.dynamic = true

      unless Rails.env.development?
        Sidekiq.configure_server do |cfg|
          cfg.on(:startup) do
            puts "Registering Sidekiq Schedule for On Deck..."
            Sidekiq.set_schedule('ondeck_update_recommendations', { cron: '* * * * *', class: 'OnDeck::UpdateRecommendationsJob' })  # Every 1 Minutes
            Sidekiq.set_schedule('ondeck_update_gds', { cron: '*/5 * * * *', class: 'OnDeck::UpdateTbaAllGdsJob' }) # Every 5 Minutes
            Sidekiq.set_schedule('ondeck_update_pps', { cron: '0 0 * * *', class: 'OnDeck::UpdateTbaAllPpsJob' })   # Every day, at midnight. Large query (~200 API requests to TBA)
          end
        end
      end
    end
  end
end
