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
      @universe ||= Hash.new({})
    end

    def self.stock(code)
      key = "stock_#{code}"
      record_in_redis = redis.get(key)
      return JSON.parse(record_in_redis) if record_in_redis

      data = Tushare::Stock::Trading.get_h_data(code, '1990-12-01', Date.today.strftime(DATE_FORMAT), 'qfq')
      redis.set(key, data.to_json)
      data
    end

    def self.index(code)
      key = "index_#{code}"
      record_in_redis = redis.get(key)
      return JSON.parse(record_in_redis) if record_in_redis

      data = Tushare::Datayes.mkt_idxd(ticker: '000300').map do |object|
        object['date'] = object['tradeDate']
        object['open'] = object['openIndex']
        object['close'] = object['closeIndex']
        object
      end
      redis.set(key, data.to_json)
      data
    end

    def self.calendar
      key = 'calendar'
      record_in_redis = redis.get(key)
      return JSON.parse(record_in_redis) if record_in_redis

      data = Tushare::Stock::Trading.trade_cal.map do |object|
        {
          'date' => Date.strptime(object['date'], '%Y/%m/%e')
                        .strftime(DATE_FORMAT),
          'is_open' => object['is_open']
        }
      end
      redis.set(key, data.to_json)
      data
    end

    def self.open_dates
      @open_dates ||= calendar.select { |object| object['is_open'] == '1' }
                              .map { |object| object['date'] }
    end
  end
end
