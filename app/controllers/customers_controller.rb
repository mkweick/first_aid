require 'odbc'

class CustomersController < ApplicationController
  before_action :require_user, except: [:home]
  before_action :set_customer, only: [:print_pick_ticket,
                                      :print_customer_receipt,
                                      :email_customer_copy]

  def home
    if logged_in?
      @open_orders = current_user.customers.order(cust_name: :asc)
    else
      redirect_to login_path
    end
  end

  def new
    @customer = Customer.new

    if params[:search] && params[:search].size > 2

      as400 = ODBC.connect('first_aid')

      if params[:search] =~ /\A\d+\z/
        sql_cust_num =  "SELECT cmcsno, cmcsnm, cmcad1, cmcad2, cmcity,
                         cmstat, cmzip4 FROM cusms
                         WHERE cmcsno = '#{ params[:search] }'"
        stmt_results = as400.run(sql_cust_num)
      else
        sql_cust_name = "SELECT cmcsno, cmcsnm, cmcad1, cmcad2, cmcity,
                         cmstat, cmzip4 FROM cusms
                         WHERE UPPER(cmcsnm) LIKE '%#{ params[:search].upcase }%'
                         ORDER BY cmcsnm ASC"
        stmt_results = as400.run(sql_cust_name)
      end

      @cust_results = stmt_results.fetch_all

      if @cust_results.nil?
        flash.now['alert'] = "No matches found."
      end

      as400.commit
      as400.disconnect
    elsif params[:search] && params[:search].size < 3
      flash.now['alert'] = "Search 3 or more characters"
    end
  end

  def create
    @customer = current_user.customers.create(customer_params)

    if @customer.save
      redirect_to kit_location_path(cust_id: @customer.id)
    else
      flash.alert = "Customer order in progress. See below."
      redirect_to root_path
    end
  end

  def print_pick_ticket
    @sorted_items = {}
    @items = @customer.items.order(kit: :asc, item_num: :asc)
    if @items.any?
      @items.pluck(:kit).uniq.each{ |kit| @sorted_items[kit] = [] }
      @items.each do |item|
        @sorted_items[item.kit] << item
      end
    end

    respond_to do |format|
      format.html { render layout: false }
      format.pdf do
        render pdf: "#{@customer.cust_name.strip}_Pick_"\
                    "#{Time.now.strftime("%d-%m-%Y")}"
      end
    end
  end

  def print_customer_receipt

  end

  def email_customer_copy
    CustomerCopyMailer.test_email("mweick@divalsafety.com").deliver_now
    flash.notice = "Customer copy emailed to mweick@divalsafety.com"
    redirect_to customer_items_path(@customer.id)
  end

  private

  def customer_params
    params.permit(:cust_num, :cust_name, :cust_line1, :cust_line2,
                  :cust_city, :cust_state, :cust_zip)
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end
end
