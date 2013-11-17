class UsersController < ApplicationController

  def twop_lookup
    if current_user
      @user ||= User.find(session[:user_id])
      @top_3_matches ||= @user.determine_match
      if @top_3_matches.empty
        render :no_match_found
      else
        @match ||= @top_3_matches.first
        @match_score = @match[1]['match_score'].round
        render :match_found
      end
      
    else
      redirect_to root_url, notice: "Please sign in first!"
    end
  end

end