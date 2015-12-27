require 'odbc'

class CustomersController < ApplicationController
  before_action :require_user

  def new
    @customer = Customer.new

    if params[:search] && params[:search].size > 2

      as400 = ODBC.connect('first_aid')

      if params[:search] =~ /\A\d+\z/
        sql_cust_num =  "SELECT cmcsno, cmcsnm, cmcad1, cmcad2, cmcity,
                         cmstat, cmzip4 FROM cusms
                         WHERE cmcsno = '#{params[:search]}'"
        stmt_results = as400.run(sql_cust_num)
      else
        sql_cust_name = "SELECT cmcsno, cmcsnm, cmcad1, cmcad2, cmcity,
                         cmstat, cmzip4 FROM cusms
                         WHERE UPPER(cmcsnm) LIKE '%#{params[:search].upcase}%'
                         ORDER BY cmcsnm ASC"
        stmt_results = as400.run(sql_cust_name)
      end

      @cust_results = stmt_results.fetch_all

      as400.commit
      as400.disconnect
    elsif params[:search] && params[:search].size < 3
      flash.now['alert'] = "Search 3 or more characters"
    end
  end

  def create
    @customer = current_user.customers.create(customer_params)

    if @customer.save
      redirect_to new_building_kit_location_path(cust_id: @customer.id)
    else
      flash.now['alert'] = "Customer order in progress. See below."
      render 'new'
    end
  end

  def edit; end

  def update; end

  def new_building_kit_location
    if params[:cust_id].nil?
      redirect_to root_path
    else
      @customer = Customer.find(params[:cust_id])
    end
  end

  def store_building_kit_location
    @customer = Customer.find(params[:cust_id])

    if !params[:building].blank? && !params[:kit].blank?
      session[:building] = params[:building]
      session[:kit] = params[:kit]
      redirect_to customer_items_path(@customer)
    else
      if !params[:building].blank?
        session[:building] = params[:building]
        flash.now['alert'] = "Kit Location is required."
      elsif !params[:kit].blank?
        session[:kit] = params[:kit]
        flash.now['alert'] = "Building name is required."
      else
        flash.now['alert'] = "Building and Kit Location are required."
      end
      render 'new_building_kit_location'
    end
  end

  def edit_building_and_kit; end

  def update_building_and_kit; end

  private

  def customer_params
    params.permit(:cust_num, :cust_name, :cust_line1, :cust_line2,
                  :cust_city, :cust_state, :cust_zip)
  end
end
