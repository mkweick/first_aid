require 'odbc'

class CustomersController < ApplicationController
  before_action :require_user,  except: [:home]
  before_action :set_customer,  except: [:home, :new, :create]
  before_action :require_owner, except: [:home, :new, :create]

  def home
    if logged_in?
      if !current_user.active
        flash.alert = "Account Deactivated."
        redirect_to login_path
      elsif admin?
        @open_orders = Customer.all.order(cust_name: :asc)
      else
        @open_orders = current_user.customers.order(cust_name: :asc)
      end
    else
      redirect_to login_path
    end
  end

  def new
    @customer = Customer.new
    if params[:search] && params[:search].size > 2
      as400 = ODBC.connect('first_aid_f')

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
      redirect_to ship_to_customer_path(@customer.id)
    end
  end

  def select_ship_to
    as400 = ODBC.connect('first_aid_f')

    sql_ship_tos =  "SELECT sashp#, sashnm, sasad1, sasad2,
                            sascty, sashst, saszip FROM addr
                     WHERE sacsno = '#{@customer.cust_num}'
                     ORDER BY sashp# ASC"
    stmt_results = as400.run(sql_ship_tos)

    @ship_tos = stmt_results.fetch_all

    as400.commit
    as400.disconnect
  end

  def set_ship_to
    if @customer.update(ship_to_params)
      as400 = ODBC.connect('first_aid_m')

      sql_insert =  "INSERT INTO favcc (fckey, fccono, fccsno, fcshp#)
                    VALUES('#{@customer.id}',
                           '01',
                           '#{@customer.cust_num}',
                           '#{@customer.ship_to_num}')"

      # insert customer# & ship-to, AS400 trigger populates ship-to credit cards
      as400.run(sql_insert)
      as400.commit
      as400.disconnect

      redirect_to kit_location_path(cust_id: @customer.id)
    else
      @customer.destroy
      flash.alert = "Order already in progress for #{@customer.cust_name} at "\
                    "Ship-to #{@customer.ship_to_num}. See below."
      redirect_to root_path
    end
  end

  def checkout; end

  def po_number; end

  def create_po_number
    if params[:po_num].blank?
      @customer.update_column(:po_num, "FIRST AID")
      flash.notice = "P.O.# reset to FIRST AID."
      redirect_to checkout_customer_path(@customer.id)
    elsif params[:po_num].strip.length > 22
      flash.alert = "P.O.# too long. (22 characters max)"
      render 'po_number'
    else
      @customer.update_column(:po_num, params[:po_num].upcase.strip)
      flash.notice = "P.O.# updated to <strong>#{@customer.po_num}</strong>."
      redirect_to checkout_customer_path(@customer.id)
    end
  end

  def set_card_on_file
    @customer.update_column(:cc_sq_num, params[:cc_sq_num])
    @customer.update_column(:cc_last_four, params[:cc_last_four])
    @customer.credit_card.destroy if @customer.credit_card
    flash.notice = "Using card on file ending in "\
                   "<strong>#{params[:cc_last_four]}</strong>"
    redirect_to checkout_customer_path(@customer.id)
  end

  def remove_card_on_file
    @customer.update_column(:cc_sq_num, nil)
    @customer.update_column(:cc_last_four, nil)
    flash.notice = "Credit card removed."
    redirect_to checkout_customer_path(@customer.id)
  end

  def pick_ticket
    @items = item_totals
    render layout: false
  end

  def put_away
    @items = sort_items_per_kit
    render layout: false
  end

  def print_customer_copy
    @items = sort_items_per_kit

    respond_to do |format|
      format.pdf do
        @title =  "Customer Copy - #{ @customer.cust_name.strip }"\
                  "(#{ @customer.cust_num }) - "

        unless Dir.exist?(Rails.root.join("orders", @customer.cust_num))
          Dir.mkdir(Rails.root.join("orders", @customer.cust_num))
        end

        render  pdf: "customer_copy",
                margin: { top: 48, bottom: 41 },
                header: { html: { template: "shared/dival_header.pdf.erb" },
                          spacing: 8 },
                footer: { html: { template: "shared/dival_footer.pdf.erb" },
                          spacing: 7},
                show_as_html: params.key?('debug'),
                save_to_file: Rails.root.join(
                          "orders",
                          "#{ @customer.cust_num }",
                          "#{ @customer.order_date.strftime("%m-%d-%y") }.pdf")
      end
    end
  end

  def get_email_address; end

  def email_customer_copy
    if params[:email] =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      @items = sort_items_per_kit

      unless Dir.exist?(Rails.root.join("orders", @customer.cust_num))
        Dir.mkdir(Rails.root.join("orders", @customer.cust_num))
      end

      customer_copy = render_to_string pdf: "customer_copy",
                      template: "customers/print_customer_copy.pdf.erb",
                      margin: { top: 48, bottom: 41 },
                      header: { html: { template: "shared/dival_header.pdf.erb" },
                                spacing: 8 },
                      footer: { html: { template: "shared/dival_footer.pdf.erb" },
                                spacing: 7}

      file_name = "#{ @customer.cust_name.strip.split(' ').join('_') }_"\
                  "First_Aid_#{ @customer.order_date.strftime("%m-%d-%y") }.pdf"
      save_path = Rails.root.join("orders", "#{ @customer.cust_num }", "#{ file_name }")
      File.open(save_path, 'wb') do |file|
        file << customer_copy
      end

      EmailWorker.perform_async("#{ params[:email] }", save_path, file_name)
      flash.notice = "Customer copy emailed to #{ params[:email] }"
      redirect_to checkout_customer_path(@customer.id)
    else
      flash.now['alert'] = "Enter a valid email address"
      render 'get_email_address'
    end
  end

  def complete_order
    as400 = ODBC.connect('first_aid_m')
    error = ""

    # delete customer ship-to credit cards from AS400 tables
    sql_delete_favcc    = "DELETE FROM favcc WHERE fckey = '#{@customer.id}'"
    sql_delete_favccrtn = "DELETE FROM favccrtn WHERE fckey = '#{@customer.id}'"
    as400.run(sql_delete_favcc)
    as400.run(sql_delete_favccrtn)

    id          = @customer.id
    username    = current_user.username.upcase
    whs         = current_user.whs_id
    cust_num    = @customer.cust_num
    ship_to_num = @customer.ship_to_num
    order_date  = @customer.order_date.strftime("%Y%m%d")
    po_num      = @customer.po_num
    cc_sq_num   = @customer.cc_sq_num if @customer.cc_sq_num
    if @customer.credit_card
      cc_number   = @customer.credit_card.decrypt
      cc_exp_date = @customer.credit_card.cc_exp_mth +
                    @customer.credit_card.cc_exp_year
    end

    @customer.items.each do |item|
      begin
        if @customer.cc_sq_num
          sql_filed_cc_order =  "INSERT INTO favorders(
                                  fvindex, fvuser, fvvan, fvcsno, fvshp#,
                                  fvdate, fvitno, fvloctn, fvqfill,
                                  fvtrprice, fvprorid, fvpo, fvsq03
                                )
                                VALUES(
                                  '#{id}', '#{username}', '#{whs}', '#{cust_num}',
                                  '#{ship_to_num}', '#{order_date}',
                                  '#{item.item_num.strip}', '#{item.kit}',
                                  '#{item.item_qty}', '#{item.item_price}',
                                  '#{item.item_price_type}', '#{po_num}',
                                  '#{cc_sq_num}'
                                )"
          as400.run(sql_filed_cc_order)

        elsif @customer.credit_card
          sql_new_cc_order =  "INSERT INTO favorders(
                                fvindex, fvuser, fvvan, fvcsno, fvshp#,
                                fvdate, fvitno, fvloctn, fvqfill, fvtrprice,
                                fvprorid, fvpo, fvcc, fvexpire
                              )
                              VALUES(
                                '#{id}', '#{username}', '#{whs}', '#{cust_num}',
                                '#{ship_to_num}', '#{order_date}',
                                '#{item.item_num.strip}', '#{item.kit}',
                                '#{item.item_qty}', '#{item.item_price}',
                                '#{item.item_price_type}', '#{po_num}',
                                '#{cc_number}', '#{cc_exp_date}'
                              )"
          as400.run(sql_new_cc_order)

        else
          sql_po_order = "INSERT INTO favorders(
                            fvindex, fvuser, fvvan, fvcsno, fvshp#, fvdate,
                            fvitno, fvloctn, fvqfill, fvtrprice, fvprorid, fvpo
                          )
                          VALUES(
                            '#{id}', '#{username}', '#{whs}', '#{cust_num}',
                            '#{ship_to_num}', '#{order_date}',
                            '#{item.item_num.strip}', '#{item.kit}',
                            '#{item.item_qty}', '#{item.item_price}',
                            '#{item.item_price_type}', '#{po_num}'
                          )"
          as400.run(sql_po_order)
        end

      rescue ODBC::Error
        error << as400.error.first

        sql_delete_items = "DELETE FROM favorders
                            WHERE fvindex = '#{ @customer.id }'"
        as400.run(sql_delete_items)
        break
      end
    end

    as400.commit
    as400.disconnect

    if error.empty?
      flash.notice = "Order for #{ @customer.cust_name } "\
                     "(#{@customer.cust_num }) submitted."
      redirect_to root_path
    else
      flash.alert = "#{ error.partition(' - ').last }<br/>"\
                    "<strong class='txt-reg'>Contact IT</strong>"
      redirect_to checkout_customer_path(@customer.id)
    end
  end

  private

  def customer_params
    params.permit(:cust_num, :cust_name)
  end

  def ship_to_params
    params.permit(:ship_to_num, :cust_line1, :cust_line2,
                  :cust_city, :cust_state, :cust_zip)
  end

  def po_params
    params.permit(:po_num)
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def require_owner
    access_denied unless @customer.user_id == current_user.id || current_user.admin
  end

  def item_totals
    @customer.items.select(:item_num, "MAX(item_desc) AS item_desc",
                                      "SUM(item_qty) AS total_qty")
                   .group(:item_num)
  end

  def sort_items_per_kit
    results = {}
    items = @customer.items.order(kit: :asc, item_num: :asc)
    if items.any?
      items.pluck(:kit).uniq.each{ |kit| results[kit] = [] }
      items.each { |item| results[item.kit] << item }
    end
    results
  end
end
