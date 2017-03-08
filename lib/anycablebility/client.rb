# frozen_string_literal: true

require 'thread'
require 'json'
require 'websocket-eventmachine-client'

require 'anycablebility/waitable'
require 'anycablebility/client/message'

module Anycablebility
  # This is a simple ActionCable client created for testing purposes
  class Client
    include Waitable

    DEFAULT_IGNORED_MESSAGE_TYPES = [:ping, :welcome]

    attr_reader :state

    def initialize(cable_url, ignore_message_types = DEFAULT_IGNORED_MESSAGE_TYPES)
      @logger = Logger.new(STDOUT)

      @cable_url = cable_url
      @ignore_message_types = ignore_message_types

      # TODO: implement state-machine
      @state = :initial

      @inbox = Queue.new
      @send_queue = Queue.new

      @logger.info "Client initialized with url: #{cable_url}"

      @thread = Thread.new do
        EventMachine.run do
          ws = WebSocket::EventMachine::Client.connect(uri: @cable_url)

          ws.onopen do
            @logger.debug('connected')
            @state = :connected
          end

          ws.onmessage do |raw_message, type|
            @logger.debug("new message: #{raw_message}, type: #{type}")

            parsed_message = parse_message(raw_message)

            if is_welcome_message(parsed_message)
              @logger.debug('welcomed')
              @state = :welcomed
            end

            if is_ping_message(parsed_message)
              until @send_queue.empty?
                message = @send_queue.pop
                EventMachine.next_tick do
                  ws.send(message)
                  @logger.debug("message sent: #{message}")
                end
              end
            end

            @inbox << raw_message unless ignore?(parsed_message)
          end
        end

        @thread.abort_on_exception = true
      end

      @logger.debug 'waiting for connection to be established'

      wait(60) { @state == :welcomed }

      @logger.debug 'connection is established!'
    end

    def send(message)
      @send_queue << message
      @logger.debug "message added to the send queue #{message}"
    end

    def recieve
      wait(20) { !@inbox.empty? } if @inbox.empty?

      @inbox.pop
    end

    private

    def parse_message(message)
      JSON.parse(message, symbolize_names: true)
    end

    def is_ping_message(parsed_message)
      parsed_message[:type] == 'ping'
    end

    def is_welcome_message(parsed_message)
      parsed_message[:type] == 'welcome'
    end

    def ignore?(parsed_message)
      return false unless parsed_message.has_key?(:type)

      type = parsed_message[:type].to_sym

      @ignore_message_types.include?(type)
    end
  end
end
