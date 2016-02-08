require 'odbc'

class CreditCardsController < ApplicationController
  before_action :set_customer
  before_action :set_credit_card, only: [:edit, :update]

  def new
    @credit_card = CreditCard.new
    as400 = ODBC.connect('first_aid_m')

    sql_insert =  "INSERT INTO favcc (fckey, fccono, fccsno, fcshp#)
                  VALUES('#{@customer.id}',
                         '01',
                         '#{@customer.cust_num}',
                         '#{@customer.ship_to_num}')"

    sql_credit_cards =  "SELECT fcsq03, fclst4, fcexpd, fcchdr, fcccod FROM FAVCCR
                        WHERE fckey = '#{@customer.id}'
                        ORDER BY fcsq03 ASC"

    # insert customer # & ship-to, wait 1 second for
    # AS400 trigger to populate ship-to credit cards
    ##as400.run(sql_insert)
    ##sleep 1
    # get credit card results
    ##results = as400.run(sql_credit_cards)

    # @ship_to_cards = results.fetch_all

    as400.commit
    as400.disconnect
  end

  def create
    @credit_card = CreditCard.new(cc_params)
    @credit_card.customer_id = @customer.id

    if @credit_card.save
      @customer.update_column(:cc_sq_num, nil)
      @customer.update_column(:cc_last_four, nil)
      flash.notice = "Credit card added"
      redirect_to checkout_customer_path(@customer.id)
    else
      @month = params[:credit_card][:cc_exp_mth]
      @year = params[:credit_card][:cc_exp_year]
      @state = params[:credit_card][:cc_state]
      params[:show] = 1
      render 'new'
    end
  end

  def edit
    @credit_card.decrypt
  end

  def update
    if @credit_card.update(cc_params)
      flash.notice = "Credit card updated"
      redirect_to checkout_customer_path(@customer.id)
    else
      render 'edit'
    end
  end

  private

  def cc_params
    params.require(:credit_card).permit(:cc_num, :cc_exp_mth, :cc_exp_year, :cc_name,
                                        :cc_line1, :cc_city, :cc_state, :cc_zip)
  end

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_credit_card
    @credit_card = CreditCard.find(params[:id])
  end
end
