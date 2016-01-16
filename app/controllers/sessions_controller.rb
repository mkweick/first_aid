class SessionsController < ApplicationController
  before_action :require_user, only: [:set_kit_location, :store_kit_location]

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

  def set_kit_location
    if params[:cust_id].nil?
      redirect_to root_path
    else
      @customer = Customer.find(params[:cust_id])
      redirect_to ship_to_customer_path(@customer.id) if @customer.ship_to_num.nil?
    end
  end

  def store_kit_location
    if params[:cust_id].nil?
      redirect_to root_path
    else
      @customer = Customer.find(params[:cust_id])

      if !params[:kit].blank?
        session[:kit] = params[:kit].upcase
        redirect_to customer_items_path(@customer)
      else
        flash.now['alert'] = "Kit Location is required."
        render 'set_kit_location'
      end
    end
  end
end
