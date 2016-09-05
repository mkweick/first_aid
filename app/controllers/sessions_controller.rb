class SessionsController < ApplicationController
  before_action :require_user, only: [:set_kit_location, :store_kit_location]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(username: params[:username])

    if user && user.active && user.authenticate(params[:password])
      login(user)
      redirect_to root_path
    elsif user && !user.active
      flash.now['alert'] = "Account Deactivated."
      render :new
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

      kits = []
      items = @customer.items
      if items.any?
        all_kits = items.pluck(:kit).uniq.map { |kit| kit =~ /\A\d+\z/ ? kit.to_i : kit }
        kit_numbers, kit_strings = all_kits.partition { |kit| kit.is_a?(Integer) }
        kits << kit_numbers.sort!
        kits << kit_strings.sort!
        kits.flatten!.map!(&:to_s)
      end

      @kits = kits

      redirect_to ship_to_customer_path(@customer.id) if @customer.ship_to_num.nil?
    end
  end

  def store_kit_location
    if params[:cust_id].nil?
      redirect_to root_path
    else
      @customer = Customer.find(params[:cust_id])

      if params[:kit].blank?
        flash.alert = "Kit Location is required."
        redirect_to kit_location_path(cust_id: params[:cust_id])
      else
        session[:kit] = params[:kit].upcase
        redirect_to customer_items_path(@customer)
      end
    end
  end
end
