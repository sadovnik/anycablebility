# frozen_string_literal: true

module Anycablebility
  module Waitable
    class TimeoutError < ::RuntimeError
    end

    def wait(timeout = 5, step = 0.1)
      start = Time.now.to_i

      until yield
        sleep step

        now = Time.now.to_i
        time_passed = now - start

        if time_passed >= timeout
          raise TimeoutError.new 'Timeout is reached'
        end
      end
    end
  end
end
