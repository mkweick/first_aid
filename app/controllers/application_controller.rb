class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  helper_method :current_user, :logged_in?, :admin?

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user && current_user.active
  end

  def admin?
    current_user.admin
  end

  def login(user)
    session[:user_id] = user.id
  end

  def logout
    session.delete(:user_id)
  end

  def require_user
    log_in_message unless logged_in?
  end

  def require_admin
    access_denied unless admin?
  end

  def log_in_message
    if (!current_user.active if current_user)
      flash.alert = "Account Deactivated."
    else
      flash.alert = "Please log in."
    end
    redirect_to login_path
  end

  def access_denied
    flash.alert = "Access Denied"
    redirect_to root_path
  end

  def escape_apostrophes(string)
    string.chars.map { |char| char == "\'" ? "\'\'" : char }.join('')
  end
end
