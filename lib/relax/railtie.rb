require 'relax'
require 'rails'

module Relax
  class Railtie < Rails::Railtie
    initializer :after_initialize do
      Relax::EventListener.logger ||= if defined?(Rails)
        Rails.logger
      elsif defined?(RAILS_DEFAULT_LOGGER)
        RAILS_DEFAULT_LOGGER
      end
    end

    rake_tasks do
      load 'relax/tasks.rb'
    end
  end
end
