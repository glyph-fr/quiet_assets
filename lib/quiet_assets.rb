require 'logger'

module QuietAssets
  class Engine < ::Rails::Engine
    # Set as true but user can override it
    config.quiet_assets = true
    config.quiet_assets_prefix = nil
    config.quiet_assets_level = Logger::ERROR

    initializer 'quiet_assets', :after => 'sprockets.environment' do |app|
      next unless app.config.quiet_assets
      # Parse PATH_INFO by assets prefix
      ASSETS_PREFIX = if app.config.quiet_assets_prefix
        %r[\A/{0,2}(#{app.config.assets.prefix}|#{app.config.quiet_assets_prefix})]
      else
        %r[\A/{0,2}#{app.config.assets.prefix}]
      end
      KEY = 'quiet_assets.old_level'
      LOG_LEVEL = app.config.quiet_assets_level
      app.config.assets.logger = false

      # Just create an alias for call in middleware
      Rails::Rack::Logger.class_eval do
        def call_with_quiet_assets(env)
          begin
            if env['PATH_INFO'] =~ ASSETS_PREFIX
              env[KEY] = Rails.logger.level
              Rails.logger.level = LOG_LEVEL
            end
            call_without_quiet_assets(env)
          ensure
            Rails.logger.level = env[KEY] if env[KEY]
          end
        end
        alias_method_chain :call, :quiet_assets
      end
    end
  end
end
