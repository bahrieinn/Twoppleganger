class User < ActiveRecord::Base

  def self.from_omniauth(auth)
    where(auth.slice("provider", "uid")).first || create_from_omniauth(auth)
  end

  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider        = auth['provider']
      user.uid             = auth['uid']
      user.name            = auth['info']['nickname']
      user.oauth_token     = auth['credentials']['token']
      user.oauth_secret    = auth['credentials']['secret']
      user.profile_pic_url = auth['info']['image']
    end
  end

  def create_thread
    Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_KEY']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = self.oauth_token
      config.access_token_secret = self.oauth_secret
    end
  end

  # https://dev.twitter.com/docs/api/1.1/get/friends/ids
  def get_friend_ids
    client = self.create_thread
    @friend_ids = client.friend_ids.entries
  end

  # https://dev.twitter.com/docs/api/1.1/get/followers/ids
  def get_follower_ids
    client = self.create_thread
    @follower_ids = client.follower_ids.entries
  end

  # https://dev.twitter.com/docs/api/1.1/get/users/lookup
  def users_lookup(user_id_array)
    client = self.create_thread
    @users = client.users(user_id_array)
  end
end
