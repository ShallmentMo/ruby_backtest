require 'redis'
require 'tushare'

module Backtest
  # Generator backtest data from different source
  # Now only support json file
  # use for fetch data
  module Data
    DATE_FORMAT = '%F'.freeze

    def self.redis
      @@redis ||= Redis.new
    end

    def self.universe
      @universe ||= {}
    end

    def self.stock(code)
      process "stock_#{code}" do
        Tushare::Stock::Trading.get_h_data(code, '1990-12-01', Date.today.strftime(DATE_FORMAT), 'qfq')
      end
    end

    def self.index(code)
      process "index_#{code}" do
        Tushare::Datayes.mkt_idxd(ticker: '000300').map do |object|
          object['date'] = object['tradeDate']
          object['open'] = object['openIndex']
          object['close'] = object['closeIndex']
          object
        end
      end
    end

    def self.calendar
      process 'calendar' do
        Tushare::Stock::Trading.trade_cal.map do |object|
          {
            'date' => Date.strptime(object['date'], '%Y/%m/%e')
                          .strftime(DATE_FORMAT),
            'is_open' => object['is_open']
          }
        end
      end
    end

    def self.open_dates
      @open_dates ||= calendar.select { |object| object['is_open'] == '1' }
                              .map { |object| object['date'] }
    end

    def self.process(key)
      return universe[key] if universe[key]

      record_in_redis = redis.get(key)
      if record_in_redis
        universe[key] = JSON.parse(record_in_redis)
        return universe[key]
      end

      data = yield
      universe[key] = data
      redis.set(key, data.to_json)
      data
    end
    private_class_method :process
  end
end
