require 'erb'
require 'yaml'
require 'sinatra'
require 'pry'

module Backtest
  # use for web page
  class Web < ::Sinatra::Base
    enable :sessions

    set :root, File.expand_path(File.dirname(__FILE__) + '/../../web')
    set :public_folder, proc { "#{root}/assets" }
    set :views, proc { "#{root}/views" }

    get '/' do
      erb :index
    end

    post '/backtest' do
      erb :chart
    end
  end
end
