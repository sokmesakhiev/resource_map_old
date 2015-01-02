class GatewaysController < ApplicationController
  before_filter :setup_guest_user, :only => :index
  before_filter :authenticate_user!, :except => :index

  def index
    method = Channel.nuntium_info_methods
    respond_to do |format|
      format.html 
      format.json { render json: params[:without_nuntium] ?  current_user.channels.where("channels.is_enable=?", true).all.as_json : current_user.channels.select('channels.id,channels.name,channels.password,channels.is_enable,channels.basic_setup, channels.advanced_setup, channels.national_setup').all.as_json(methods: method)}
    end
  end

  def create
    channel = current_user.channels.new params[:gateway]
    if channel.valid?
      channel.save!
      current_user.gateway_count += 1
      current_user.update_successful_outcome_status
      current_user.save!(:validate => false)
      render json: channel.as_json
    else
      render json: {status: 200, errors: channel.errors.full_messages}
    end
  end

  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:gateway]
    render json: channel
  end

  def destroy
    channel = Channel.find params[:id]
    channel.destroy
    render json: channel 
  end

  def try
    channel = Channel.find params[:gateway_id]
    SmsNuntium.notify_sms [params[:phone_number]], 'Welcome to resource map!', channel.nuntium_channel_name, nil
    render json: channel.as_json
  end
  
  def status
    channel = Channel.find params[:id] 
    channel.is_enable = params[:status]
    channel.save!
    render json: channel
  end
end
