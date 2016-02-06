require 'odbc'

class CustomersController < ApplicationController
  before_action :require_user,  except: [:home]
  before_action :set_customer,  except: [:home, :new, :create]

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

  def print_pick_ticket
    @items = get_and_sort_items

    respond_to do |format|
      format.html { render layout: false }
      format.pdf do
        @title = "Pick Ticket - #{ @customer.cust_name.strip } - "
        render pdf: "pick_ticket",
                    margin: { top: 38, bottom: 18 },
                    header: { html: { template: "customers/pick_ticket_header.pdf.erb" },
                              spacing: 8 },
                    footer: { center: "Page [page] of [topage]",
                              spacing: 7,
                              font_size: 8,
                              font_name: "sans-serif" }
      end
    end
  end

  def print_customer_copy
    @items = get_and_sort_items

    respond_to do |format|
      format.pdf do
        @title =  "Customer Copy - #{ @customer.cust_name.strip }"\
                  "(#{ @customer.cust_num }) - "

        unless Dir.exist?("/home/rails/first_aid/orders/#{ @customer.cust_num }")
          Dir.mkdir("/home/rails/first_aid/orders/#{ @customer.cust_num }")
        end

        render  pdf: "customer_copy",
                margin: { top: 48, bottom: 41 },
                header: { html: { template: "shared/dival_header.pdf.erb" },
                          spacing: 8 },
                footer: { html: { template: "shared/dival_footer.pdf.erb" },
                          spacing: 7},
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
      @items = get_and_sort_items

      unless Dir.exist?("/home/rails/first_aid/orders/#{ @customer.cust_num }")
        Dir.mkdir("/home/rails/first_aid/orders/#{ @customer.cust_num }")
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

    @customer.items.each do |item|
      sql_insert_items = "INSERT INTO favtrans15(
                                      fvindex, fvuser, fvvan, fvpo, fvcsno,
                                      fvshp#, fvdate, fvitno, fvloctn, fvqneed,
                                      fvqfill, fvtrprice, fvprorid)
                          VALUES ('#{@customer.id}',
                                  '#{current_user.username.upcase}',
                                  '#{current_user.whs_id}',
                                  '#{@customer.po_num}',
                                  '#{@customer.cust_num}',
                                  '#{@customer.ship_to_num}',
                                  '#{@customer.order_date.strftime("%Y%m%d")}',
                                  '#{item.item_num.strip}',
                                  '#{item.kit}',
                                  '#{item.item_qty}',
                                  '#{item.item_qty}',
                                  '#{item.item_price}',
                                  '#{item.item_price_type}')"
      begin
        as400.run(sql_insert_items)
      rescue ODBC::Error
        error << as400.error.first

        sql_delete_items = "DELETE FROM favtrans15
                            WHERE fvuser = '#{ current_user.username.upcase }'
                            AND   fvvan = '#{ current_user.whs_id }'
                            AND   fvcsno = '#{ @customer.cust_num }'"
        as400.run(sql_delete_items)

        break
      end
    end

    as400.commit
    as400.disconnect

    if error.empty?
      flash.notice = "Order for #{ @customer.cust_name } "\
                     "(#{@customer.cust_num }) submitted succesfully!"
      redirect_to root_path
    else
      flash.alert = "#{ error.partition(' - ').last }<br/>"\
                    "<strong class='txt-reg'>Contact IT</strong>"
      redirect_to customer_items_path(@customer.id)
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
    params[:id] ? (@customer = Customer.find(params[:id])) : (redirect_to root_path)
  end

  def get_and_sort_items
    results = {}
    items = @customer.items.order(kit: :asc, item_num: :asc)
    if items.any?
      items.pluck(:kit).uniq.each{ |kit| results[kit] = [] }
      items.each { |item| results[item.kit] << item }
    end
    results
  end
end
