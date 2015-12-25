class OrdersController < ApplicationController

  def new
    logged_in? ? (@user = User.find session[:user_id]):(redirect_to login_path)
  end
end
