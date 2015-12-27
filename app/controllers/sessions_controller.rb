class SessionsController < ApplicationController

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(username: params[:username])

    if user && user.authenticate(params[:password])
      login(user)
      redirect_to root_path
    else
      flash.now['alert'] = "Invalid username/password"
      render :new
    end
  end

  def destroy
    if logged_in?
      logout
      flash.notice = "You have been logged out"
      redirect_to login_path
    else
      redirect_to login_path
    end
  end
end
