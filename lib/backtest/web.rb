require 'erb'
require 'yaml'
require 'sinatra'
require 'pry'
require 'flamegraph'

module Backtest
  # flamegraph middleware
  class FlamegraphMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
      # 返回保存的 flamegraph
      if params['pp'] == 'flamegraph'
        return [
          200,
          {
            'Content-Type' => 'text/html;charset=utf-8',
            'Content-Length' => @@flamegraph_html.size.to_s
          },
          [@@flamegraph_html]
        ]
      end

      return @app.call(env) unless env['HTTP_ACCEPT'] =~ /html/ ||
                                   env['REQUEST_METHOD'] != 'GET'

      result = nil
      @@flamegraph_html = Flamegraph.generate do
        result = @app.call(env)
      end
      result
    end
  end

  # use for web page
  class Web < ::Sinatra::Base
    enable :sessions
    use FlamegraphMiddleware

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
