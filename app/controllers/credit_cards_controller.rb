require 'odbc'

class CreditCardsController < ApplicationController
  before_action :set_customer
  before_action :set_credit_card, only: [:edit, :update, :destroy]

  def new
    @credit_card = CreditCard.new
    as400 = ODBC.connect('first_aid_m')

    sql_credit_cards =  "SELECT fcsq03, fclst4, fcexpd, fcchdr, fcccod
                        FROM favccrtn
                        WHERE fckey = '#{@customer.id}'
                        ORDER BY fcsq03 ASC"

    # get ship-to credit cards
    results = as400.run(sql_credit_cards)
    @ship_to_cards = results.fetch_all

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

  def destroy
    @credit_card.destroy
    if @customer.credit_card
      flash.alert = "Card can't be removed. Contact IT."
    else
      flash.notice = "Credit card removed."
    end

    redirect_to checkout_customer_path(@customer.id)
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
