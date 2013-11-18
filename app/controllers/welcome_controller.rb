class WelcomeController < ApplicationController

  def index
    if current_user.network_over_limit?
      render :warning
    else
      render :index
    end
  end
  
end