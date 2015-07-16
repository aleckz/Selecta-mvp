require 'sinatra/base'
require 'sinatra/flash'
require 'pry'
require 'json'
require_relative './data_mapper_setup'


class Selecta < Sinatra::Base

  enable :sessions
  set :session_secret, 'secret'
  register Sinatra::Flash
  set :views, proc {File.join(root, '.', 'views')}

  get '/' do
    @links = Link.all.sort_by { |link| -link.likes.count }
    @current_user = User.get current_user

    erb :index
  end

  post '/user' do
    user = User.new(
      username:              params[:username             ],
      email:                 params[:email                ],
      password:              params[:password             ],
      password_confirmation: params[:password_confirmation]
    )
    if user.save
      session[:user_id] = user.id

      content_type :json
      {userCreated: true}.to_json
    else
      content_type :json
      {userCreated: false}.to_json
    end

  end

  post '/link' do
    link = Link.new(
      title:   params[:title],
      url:     params[:url  ],
      user_id: current_user
    )
    if link.save
      flash[:notice] = 'Submission successful'
    else
      flash.now[:errors] = link.errors.full_messages
    end

    redirect '/'
  end

  post '/like' do
    like = Like.new(
      user_id: current_user,
      link_id: params[:link_id]
    )
    like.save unless already_liked? params[:link_id]

    erb :index
  end

  post '/session' do
    user = User.authenticate params

    if user
      session[:user_id] = user.id
      content_type :json
      {userRetrieved: true}.to_json
    else
      content_type :json
      {userRetrieved: false}.to_json
    end
  end

  post '/logout' do
    session[:user_id] = nil

    redirect '/'
  end

  def already_liked? link_id_checked
    User.get(session[:user_id]).likes.any? do |like|
      like.link_id == link_id_checked
    end
  end

  def current_user
    session[:user_id]
  end

  run! if app_file == $0
end
