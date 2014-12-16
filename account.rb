# coding: utf-8

require "twitter"

class Account
  attr_reader :rest

  def initialize(token)
    @rest = Twitter::REST::Client.new(token)
    @stream = Twitter::Streaming::Client.new(token)
    @callbacks = {}
  end

  def start
    loop do
      @stream.user do |obj|
        following = false
        case obj
        when Twitter::Tweet
          callback(:tweet, obj) if is_allowed?(obj.user.id)
        when Twitter::Streaming::DeletedTweet
          callback(:delete, obj) if is_allowed?(obj.user_id)
        when Twitter::Streaming::Event
          callback(:event, obj) if is_allowed?(obj.source.id)
        when Twitter::Streaming::FriendList
          @followings = obj
          @followings << user.id
          callback(:friends, obj)
        end
      end
    end
  end

  def user
    @rest.verify_credentials
  end

  def add_plugin(filename)
    Plugin.new(self, filename)
  end

  def register_callback(event, &blk)
    @callbacks[event] ||= []
    @callbacks[event] << blk
  end

  private
  def callback(event, obj)
    @callbacks[event].each{|c|c.call(obj)} if @callbacks.key?(event)
  end

  def is_allowed?(user_id)
    following = false
    @followings.each do |id|
      if user_id == id
        following = true
        break
      end
    end
    return following
  end
end
