require 'odbc'

class ItemsController < ApplicationController
  before_action :require_user
  before_action :set_customer, only: [:index, :create, :edit]
  before_action :set_item, only: [:edit, :update, :destroy]

  def index
    @sorted_items = {}
    @items = @customer.items.order(building: :asc, kit: :asc, item_num: :asc)
    if @items.any?
      @items.pluck(:building).uniq.each{|building| @sorted_items[building] = {}}
      @items.each do |item|
        unless @sorted_items[item.building][item.kit]
          @sorted_items[item.building][item.kit] = []
        end
      end
      @items.each do |item|
        @sorted_items[item.building][item.kit] << item
      end
    end

    if (params[:get_pricing] && !params[:item_num].blank?) ||
       (params[:item_search] && params[:item_num].size > 2)

      item = params[:item_num].upcase
      as400 = ODBC.connect('first_aid')

      if params[:get_pricing]
        sql_item_num = "SELECT a.imitno, a.imitd1 || ' ' || a.imitd2 as itm_desc,
                        CAST(ROUND(b.ibohq1,2) AS NUMERIC(10,2)) FROM itmst AS a
                        JOIN itbal AS b ON a.imitno = b.ibitno
                        WHERE b.ibwhid = '#{current_user.whs_id}' AND
                              UPPER(a.imitno) = '#{item}'"
        stmt_item_num = as400.run(sql_item_num)
        find_item_num = stmt_item_num.fetch_all

        if find_item_num.nil?
          flash.now['alert'] = "Item is not in your warehouse (#{current_user.whs_id})"
        else
          itm_num = find_item_num.first[0].strip
          itm_desc = find_item_num.first[1].strip
          avail_qty = find_item_num.first[2].to_i

          redirect_to item_pricing_customer_path(@customer.id,
                                                 item_num: itm_num,
                                                 item_desc: itm_desc,
                                                 avail_qty: avail_qty)
        end

      elsif params[:item_search]
        sql_item_search = "SELECT a.imitno, a.imitd1 || ' ' || a.imitd2 as itm_desc,
                           CAST(ROUND(b.ibohq1,2) AS NUMERIC(10,2)) FROM itmst AS a
                           JOIN itbal AS b ON a.imitno = b.ibitno
                           WHERE b.ibwhid = '#{current_user.whs_id}' AND
                                (UPPER(a.imitd1) LIKE '%#{item}%' OR
                                 UPPER(a.imitd2) LIKE '%#{item}%')
                           ORDER BY a.imitno ASC"
        stmt_results = as400.run(sql_item_search)
        @item_results = stmt_results.fetch_all

        if @item_results.nil?
          flash.now['alert'] = "No matches found."
        end
      end

      as400.commit
      as400.disconnect

    elsif params[:get_pricing] && params[:item_num].blank?
      flash.now['alert'] = "Item # can't be blank"
    elsif params[:item_search] && params[:item_num].size < 3
      flash.now['alert'] = "Item search 3 or more characters"
    end
  end

  def get_item_pricing
    @customer = Customer.find(params[:id])
    itm_num = params[:item_num].upcase
    itm_desc = params[:item_desc]
    avail_qty = params[:avail_qty]

    as400 = ODBC.connect('first_aid')

    sql_check_hist_pricing = "SELECT obaslp FROM APLUS83MTE.hspalm
                              WHERE UPPER(obitno) = '#{itm_num}' AND
                                    obcsno = '#{@customer.cust_num}'"
    stmt_hist_check = as400.run(sql_check_hist_pricing)
    hist_pricing = stmt_hist_check.fetch_all

    if hist_pricing.nil?
      sql_get_list_pricing = "SELECT imlpr1 FROM itmst
                              WHERE UPPER(imitno) = '#{itm_num}'"
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
                                      item_num: itm_num, item_desc: itm_desc,
                                      avail_qty: avail_qty,
                                      item_price: history_price,
                                      item_price_type: "HIST")
    elsif list_price1
      redirect_to customer_items_path(@customer.id, item_display: 1,
                                      item_num: itm_num, item_desc: itm_desc,
                                      avail_qty: avail_qty,
                                      item_price: list_price1,
                                      item_price_type: "LIST")
    end
  end

  def create
    @dup_item = @customer.items.where "item_num = ? AND building = ? AND kit = ?",
                                       params[:item_num],
                                       params[:building],
                                       params[:kit]
    if @dup_item.any?
      flash.alert = "Item #{params[:item_num]} already added in
                     #{params[:building]} - #{params[:kit]}. Adjust Qty below."
      redirect_to customer_items_path(@customer.id)

    elsif params[:item_qty].to_i > params[:avail_qty].to_i
      flash.alert = "Quantity exceeds available of #{params[:avail_qty].to_i}"
      params[:item_display] = 1
      redirect_to customer_items_path(params.except(:authenticity_token,
                                                    :building, :kit, :commit,
                                                    :controller, :action))
    elsif params[:item_qty] =~ /\A\d+\z/ && params[:item_qty].to_i > 0
      @item = @customer.items.create(item_params)

      if @item.save
        flash.notice = "Item #{@item.item_num} added to order."
        redirect_to customer_items_path(@customer.id)
      else
        flash.alert = "Whoops! Something went wrong."
        params[:item_display] = 1
        redirect_to customer_items_path(params.except(:authenticity_token,
                                                      :building, :kit, :commit,
                                                      :controller, :action))
      end
    else
      flash.alert = "Quantity must be a positive number"
      params[:item_display] = 1
      redirect_to customer_items_path(params.except(:authenticity_token,
                                                    :building, :kit, :commit,
                                                    :controller, :action))
    end
  end

  def edit
    item = @item.item_num.upcase
    as400 = ODBC.connect('first_aid')

    sql_item_qty = "SELECT CAST(ROUND(ibohq1,2) AS NUMERIC(10,2)) FROM itbal
                    WHERE ibwhid = '#{current_user.whs_id}' AND
                           UPPER(ibitno) = '#{item}'"
    stmt_item_qty = as400.run(sql_item_qty)
    get_item_qty = stmt_item_qty.fetch_all

    @avail_qty = get_item_qty.first[0].to_i

    as400.commit
    as400.disconnect
  end

  def update
    if @item.update(item_params)
      redirect_to customer_items_path
    else
      @item.reload
      render :edit
    end
  end

  def destroy
    if @item.destroy
      flash.notice = "Item #{@item.item_num} removed from Kit #{@item.kit} " +
                     "in Building #{@item.building}"
    else
      flash.alert = "Item #{@item.item_num} can't be removed from " +
                    "Kit #{@item.kit} in Building #{@item.building}"
    end
    redirect_to customer_items_path
  end

  private

  def item_params
    params.permit(:building, :kit, :item_num, :item_desc, :item_qty,
                  :item_price, :item_price_type)
  end

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_item
    @item = Item.find(params[:id])
  end
end