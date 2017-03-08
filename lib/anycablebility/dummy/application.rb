# frozen_string_literal: true

require 'rails'

module Dummy
  class Application < Rails::Application
    config.time_zone = 'Moscow'
  end
end

Rails.application.initialize!
