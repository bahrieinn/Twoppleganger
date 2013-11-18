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
      user.follower_count  = auth['extra']['raw_info']['followers_count'].to_i
      user.following_count = auth['extra']['raw_info']['friends_count'].to_i
      user.tweet_count     = auth['extra']['raw_info']['statuses_count'].to_i
    end
  end

  def network_over_limit?
    (self.follower_count + self.following_count) >= 18_000
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

  def determine_match
    friend_follower_ids = (self.get_friend_ids + self.get_follower_ids).uniq
    network_list = self.users_lookup(friend_follower_ids)
    network_list_with_scores = {}

    network_list.each do |user|
      network_list_with_scores[user.screen_name] = {
        'match_score' => calculate_match_score(user),
        'profile_image' => user.profile_image_url
      }
    end
    network_list.sort_by { |user, info| info['match_score'] }.reverse[0..4]
  end

  def calculate_match_score(user)
    follower_index = self.get_follower_index(user)
    following_index = self.get_following_index(user)
    tweet_index = self.get_tweet_index(user)

    match_score = 1 - ((follower_index + following_index + tweet_index) / 3).to_f
    match_score = match_score * 100
  end

  def get_follower_index(user)
    (self.follower_count - user.followers_count).abs / (self.follower_count + user.followers_count).to_f
  end

  def get_following_index(user)
    (self.following_count - user.friends_count).abs / (self.following_count + user.friends_count).to_f
  end

  def get_tweet_index(user)
    (self.tweet_count - user.tweets_count).abs / (self.tweet_count + user.tweets_count).to_f
  end

end
