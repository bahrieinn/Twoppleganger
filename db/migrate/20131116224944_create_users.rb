class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :oauth_token
      t.string :oauth_secret
      t.string :profile_pic_url
      t.integer :follower_count
      t.integer :following_count
      t.integer :tweet_count

      t.timestamps
    end
  end
end
