# frozen_string_literal: true

require 'minitest/spec'
require 'anycablebility/client'

describe 'WebSocket server' do
  CABLE_URL = 'ws://0.0.0.0:8080/cable'

  describe 'basic functionality' do
    it 'welcomes on connect' do
      client = Anycablebility::Client.new(CABLE_URL, [])
      assert_equal client.recieve, { type: 'welcome' }.to_json
    end
  end

  describe 'subscribtions' do
    before do
      @client = Anycablebility::Client.new(CABLE_URL)
    end

    it 'proxies subscription request and confirmation' do
      channel = 'JustChannel'

      subscribe_request = { command: 'subscribe', identifier: { channel: channel }.to_json }.to_json

      @client.send(subscribe_request)

      subscription_confirmation = { identifier: { channel: channel }.to_json, type: 'confirm_subscription' }.to_json

      assert_equal subscription_confirmation, @client.recieve
    end

    it 'proxies trasmissions' do
      channel = 'TransmitSubscriptionChannel'

      subscribe_request = { command: 'subscribe', identifier: { channel: channel }.to_json }.to_json

      @client.send(subscribe_request)

      transmission = { identifier: { channel: channel }.to_json, message: 'hello' }.to_json

      assert_equal transmission, @client.recieve

      subscription_confirmation = { identifier: { channel: channel }.to_json, type: 'confirm_subscription' }.to_json

      assert_equal subscription_confirmation, @client.recieve
    end
  end
end
