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
      start_date = Date.strptime @strategy.start_date
      end_date = Date.strptime @strategy.end_date
      @profit_percent_data = (start_date..end_date).to_a.map do |date|
        capital = @strategy.account.capital(date)[:worth]
        init_capital = @strategy.capital
        profit_percent = (capital - init_capital).to_f / init_capital
        [date.strftime(Data::DATE_FORMAT), profit_percent]
      end
      erb :chart
    end
  end
end
