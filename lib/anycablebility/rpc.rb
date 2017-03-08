# frozen_string_literal: true

require 'anycablebility/dummy/application'
require 'anycable/rails'
require 'anycable-rails'

module Anycablebility
  # RPC server
  class Rpc
    class << self
      def run(redis_url)
        raise 'Already running' if is_running?

        configure_anycable(redis_url)

        load_dummy

        thread = Thread.new do
          Anycable::Server.start
        end

        thread.abort_on_exception = true
      end

      def stop
        raise 'Already stopped' unless is_running?

        Anycable::Server.grpc_server.stop
      end

      def is_running?
        grpc_server_created? && Anycable::Server.grpc_server.running?
      end

      private

      def grpc_server_created?
        !Anycable::Server.grpc_server.nil?
      end

      def configure_anycable(redis_url)
        Anycable.configure do |config|
          config.debug = true
          config.redis_url = redis_url
          config.connection_factory = ActionCable.server.config.connection_class.call
        end
      end

      def load_dummy
        pattern = File.expand_path('dummy/**/*.rb', __dir__)

        Dir.glob(pattern).each { |file| require file }

        Rails.application.eager_load!
      end
    end
  end
end
