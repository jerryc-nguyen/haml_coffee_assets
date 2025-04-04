# coding: UTF-8

require 'haml_coffee_assets/action_view/resolver'

module HamlCoffeeAssets
  module Rails

    # Haml Coffee Assets Rails engine that can be configured
    # per environment and registers the tilt template.
    #
    class Engine < ::Rails::Engine

      config.hamlcoffee = ::HamlCoffeeAssets.config

      # Initialize Haml Coffee Assets after Sprockets
      #
      initializer 'sprockets.hamlcoffeeassets', group: :all, after: 'sprockets.environment' do |app|
        require 'haml_coffee_assets/action_view/template_handler'

        # No server side template support with AMD
        if ::HamlCoffeeAssets.config.placement == 'global'

          # Register Tilt template (for ActionView)
          ActiveSupport.on_load(:action_view) do
            ::ActionView::Template.register_template_handler(:hamlc, ::HamlCoffeeAssets::ActionView::TemplateHandler)
          end

          # Add template path to ActionController's view paths.
          ActiveSupport.on_load(:action_controller) do
            path = ::HamlCoffeeAssets.config.templates_path
            resolver = ::HamlCoffeeAssets::ActionView::Resolver.new(path)
            ::ActionController::Base.append_view_path(resolver)
          end
        end

        config.assets.configure do |env|
          if env.respond_to?(:register_transformer)
            env.register_mime_type 'text/hamlc', extensions: ['.hamlc']
            env.register_transformer 'text/hamlc', 'application/javascript', ::HamlCoffeeAssets::Transformer

            env.register_mime_type 'text/jst+hamlc', extensions: ['.jst.hamlc']
            env.register_transformer 'text/jst+hamlc', 'application/javascript+function', ::HamlCoffeeAssets::Transformer

            # support for chaining via ERB, documented via https://github.com/rails/sprockets/pull/807
            env.register_mime_type 'text/hamlc+ruby', extensions: ['.hamlc.erb']
            env.register_transformer 'text/hamlc+ruby', 'text/hamlc', ::Sprockets::ERBProcessor

            env.register_mime_type 'text/jst+hamlc+ruby', extensions: ['.jst.hamlc.erb']
            env.register_transformer 'text/jst+hamlc+ruby', 'text/jst+hamlc', ::Sprockets::ERBProcessor
          end

          if env.respond_to?(:register_engine)
            args = ['.hamlc', ::HamlCoffeeAssets::Transformer]
            args << { mime_type: 'text/hamlc', silence_deprecation: true } if Sprockets::VERSION.start_with?('3')
            env.register_engine(*args)
          end
        end
      end

    end

  end
end
