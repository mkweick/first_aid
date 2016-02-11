require 'odbc'

class UsersController < ApplicationController
  before_action :require_user
  before_action :require_admin, except: [:edit, :update]
  before_action :set_user, except: [:index, :new, :create]
  before_action :require_owner, only: [:edit, :update]
  before_action :set_filter_sort, only: [:index]

  def index
    if params[:filter]
      @users = User.select("id, first_name, last_name, whs_id, active")
                   .where(admin: false)
                   .order("#{@filter} #{@sort}")
    else
      @users = User.select("id, first_name, last_name, whs_id, active")
                   .where(admin: false)
                   .order(active: :desc, first_name: :asc)
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      flash.notice = "User #{@user.username} created."
      redirect_to users_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      if admin?
        flash.notice = "#{@user.first_name} #{@user.last_name} updated."
        redirect_to users_path
      else
        flash.notice = "Password updated."
        redirect_to root_path
      end
    else
      render :edit
    end
  end

  def activate
    @user.update_column(:active, true)
    flash.notice = "#{@user.first_name} #{@user.last_name} activated."
    redirect_to users_path
  end

  def deactivate
    @user.update_column(:active, false)
    flash.notice = "#{@user.first_name} #{@user.last_name} deactivated."
    redirect_to users_path
  end

  def destroy; end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :username, :whs_id,
                                 :password, :password_confirmation)
  end

  def set_user
    @user = User.find(params[:id]) if params[:id]
  end

  def require_owner
    access_denied unless current_user.admin || @user == current_user
  end

  def set_filter_sort
    case params[:filter]
    when 'name' then @filter = 'first_name'
    when 'whs'  then @filter = 'whs_id'
    else @filter = 'active'
    end

    params[:sort] == 'd' ? (@sort = 'desc') : (@sort = 'asc')
  end
end
