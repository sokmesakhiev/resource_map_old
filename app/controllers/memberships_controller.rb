class MembershipsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:create, :set_layer_access, :set_admin, :unset_admin, :index]
  
  include ApplicationHelper 
  
  def index
    layer_memberships = collection.layer_memberships.all.inject({}) do |hash, membership|
      (hash[membership.user_id] ||= []) << membership
      hash
    end
    memberships = collection.memberships.includes([:user, :read_sites_permission, :write_sites_permission]).all.map do |membership|
      user_display_name = User.generate_user_display_name membership.user
      if user_display_name == membership.user.phone_number
        user_phone_number = ""
      else
        user_phone_number = membership.user.phone_number
      end
      
      {
        user_id: membership.user_id,
        user_display_name: user_display_name,
        user_phone_number: user_phone_number,
        admin: membership.admin?,
        layers: (layer_memberships[membership.user_id] || []).map{|x| {layer_id: x.layer_id, read: x.read?, write: x.write?}},
        sites: {
          none: membership.none_sites_permission,
          read: membership.read_sites_permission,
          write: membership.write_sites_permission
        }
      }
    end
    render json: memberships, :root => false
  end

  def create
    user = User.find_by_email params[:email]
    if user && !user.memberships.where(:collection_id => collection.id).exists?
      user.memberships.create! :collection_id => collection.id
      render json: {status: :added, user_id: user.id, user_display_name: user.display_name}
    else
      register_new_member
      #render json: {status: :not_added}
    end
  end

  def invitable
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id not in (?)", collection.memberships.pluck(:user_id)).
      order('email')
    render json: users.pluck(:email), :root => false
  end

  def search
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id in (?)", collection.memberships.pluck(:user_id)).
      order('email')

    render json: users.pluck(:email), :root => false
  end

  def destroy
    membership = collection.memberships.find_by_user_id params[:id]
    if leave_collection_permission? || membership.user_id != current_user.id
      membership.destroy
    end
    redirect_to collections_path
  end

  def set_layer_access
    membership = collection.memberships.find_by_user_id params[:id]
    membership.set_layer_access params
    render json: :ok
  end

  def set_admin
    change_admin_flag true
  end

  def unset_admin
    change_admin_flag false
  end

  def register_new_member
    if (params[:user][:email].strip.length == 0)
      params[:user][:email] = User.generate_default_email
    end

    params[:user][:password] = User.generate_random_password if params[:user]
    if (User.find_all_by_phone_number(params[:user][:phone_number]).count == 0)
      user = User.create params[:user] if params[:user]    
      user.confirmed_at = Time.now
      if user.save!
        user = User.find_by_email params[:user][:email]
        user.memberships.create! admin: false, user_id: user.id, collection_id: collection.id
        membership = collection.memberships.find_by_user_id user.id
        user_display_name = User.generate_user_display_name user  
        if membership
          collection.layers.each do |l|
            membership.set_layer_access :access => true, :layer_id => l.id, :verb => "read"
          end 
        end
        layer_memberships = collection.layer_memberships.all.inject({}) do |hash, membership|
          (hash[membership.user_id] ||= []) << membership
          hash
        end
        render json: {
                      status: :ok, 
                      user_id: user.id,
                      layers: (layer_memberships[membership.user_id] || []).map{|x| {layer_id: x.layer_id, read: x.read?, write: x.write?}}, 
                      user_display_name: user_display_name
                      } 
      else
        render json: :unsaved
      end
    else
      render json: {status: :phone_existed}
    end
  end

  private

  def change_admin_flag(new_value)
    membership = collection.memberships.find_by_user_id params[:id]
    membership.admin = new_value
    membership.save!

    render json: :ok
  end
end
