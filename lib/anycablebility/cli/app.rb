# frozen_string_literal: true

require 'anycablebility/rpc'

module Anycablebility
  module Cli
    class App
      DEFAULT_REDIS_URL = 'redis://localhost:6379'

      def run
        run_rpc

        run_tests

        stop_rpc
      rescue => e
        stop_rpc if rpc_is_running?
        raise e
      end

      private

      def run_rpc
        Anycablebility::Rpc.run(DEFAULT_REDIS_URL)
      end

      def stop_rpc
        Anycablebility::Rpc.stop
      end

      def rpc_is_running?
        Anycablebility::Rpc.is_running?
      end

      def run_tests
        load_tests
        MiniTest.run
      end

      def load_tests
        require 'anycablebility/tests'
      end
    end
  end
end
