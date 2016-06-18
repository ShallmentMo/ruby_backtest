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
      # santize params, error handling
      @code = params['code']
      @strategy = eval(@code)
      Backtest.test @strategy
      @profit_percent_data =
        @strategy.account
                 .capital(@strategy.start_date, @strategy.end_date).map do |o|
          capital = o[:worth]
          init_capital = @strategy.capital
          profit_percent = (capital - init_capital).to_f / init_capital
          [o[:date], profit_percent]
        end
      erb :chart
    end
  end
end
