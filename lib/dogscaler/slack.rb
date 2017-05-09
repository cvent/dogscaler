require 'slack-ruby-client'

module Dogscaler
  class SlackClient
    include Logging
    def initialize(api_token, channel)
      Slack.configure do |config|
        config.token = api_token
      end
      @client = Slack::Web::Client.new
      @channel = channel
    end

    def send_message(message)
      @client.chat_postMessage(:channel => @channel, :text => message, :as_user => true)
    end

  end
end

