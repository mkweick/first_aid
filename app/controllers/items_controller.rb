require 'odbc'

class ItemsController < ApplicationController
  before_action :require_user
  before_action :set_customer, only: [:index, :create]

  def index
    @items = @customer.items.order(building: :asc, kit: :asc, item_num: :asc)

    if (params[:get_pricing] && !params[:item].blank?) ||
       (params[:item_search] && params[:item].size > 2)
      item = params[:item].upcase
      as400 = ODBC.connect('first_aid')

      if params[:get_pricing]

      elsif params[:item_search]
        sql_item_search = "SELECT a.imitno, a.imitd1 || ' ' || a.imitd2 as itm_desc,
                           CAST(ROUND(b.ibohq1,2) AS NUMERIC(10,2)) FROM itmst AS a
                           JOIN itbal AS b ON a.imitno = b.ibitno
                           WHERE b.ibwhid = '#{current_user.whs_id}' AND
                                (UPPER(a.imitd1) LIKE '%#{item}%' OR
                                 UPPER(a.imitd2) LIKE '%#{item}%')
                           ORDER BY a.imitno ASC"
        stmt_results = as400.run(sql_item_search)
      end

      @item_results = stmt_results.fetch_all

      as400.commit
      as400.disconnect

    elsif params[:get_pricing] && params[:item].blank?
      flash.now['alert'] = "Item # can't be blank"
    elsif params[:item_search] && params[:item].size < 3
      flash.now['alert'] = "Item search 3 or more characters"
    end
  end

  def get_item_pricing
    @customer = Customer.find(params[:id])
    item = params[:item_num].upcase
    desc = params[:item_desc]
    qty = params[:item_qty]

    as400 = ODBC.connect('first_aid')

    sql_check_hist_pricing = "SELECT obaslp FROM APLUS83MTE.hspalm
                              WHERE UPPER(obitno) = '#{item}' AND
                                    obcsno = '#{@customer.cust_num}'"
    stmt_hist_check = as400.run(sql_check_hist_pricing)
    hist_pricing = stmt_hist_check.fetch_all

    if hist_pricing.nil?
      sql_get_list_pricing = "SELECT imlpr1 FROM itmst
                              WHERE UPPER(imitno) = '#{item}'"
      stmt_list_price = as400.run(sql_get_list_pricing)
      list_pricing = stmt_list_price.fetch_all
      list_price1 = list_pricing.first[0]
    else
      history_price = hist_pricing.first[0]
    end

    as400.commit
    as400.disconnect

    if history_price
      redirect_to customer_items_path(@customer.id, item_display: 1,
                                      item: item, item_desc: desc, item_qty: qty,
                                      item_price: history_price, item_price_type: "HIST")
    elsif list_price1
      redirect_to customer_items_path(@customer.id, item_display: 1,
                                      item: item, item_desc: desc, item_qty: qty,
                                      item_price: list_price1, item_price_type: "LIST")
    end
  end

  def create
    @item = @customer.items.create(item_params)

    if @item.save
      flash.notice = "Item #{@item.item_num} added to order."
      redirect_to customer_items_path(@customer.id)
    else
      flash.now['alert'] = "Whoops! Something Wrong."
      render 'index'
    end
  end

  def show

  end

  def edit

  end

  def update

  end

  def destroy

  end

  private

  def item_params
    params.permit(:building, :kit, :item_num, :item_desc, :item_qty,
                  :item_price, :item_price_type)
  end

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end
end
