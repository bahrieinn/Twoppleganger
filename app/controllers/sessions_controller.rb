class SessionsController < ApplicationController

  def create
    user = User.from_omniauth(env['omniauth.auth'])
    session[:user_id] = user.id
    redirect_to profile_path, notice: "Signed In!"
  end

end