Sidekiq.configure_server do |cfg|
  cfg.redis = { url: 'redis://redis:6379/0' }  
end

Sidekiq.configure_client do |cfg|
  cfg.redis = { url: 'redis://redis:6379/0' }
end