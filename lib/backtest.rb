require 'json'
require 'gnuplotrb'
require 'bigdecimal'

Dir['./lib/backtest/*.rb'].each { |file| require file }

# Backtest namespace
module Backtest
  def self.test(strategy)
    # 初始化账户金额
    account = Account.new(strategy.capital)
    strategy.account = account

    # 从 strategy.start_date 迭代到 strategy.end_date
    # 需要判断是否是开市的日子
    # 需要根据 strategy.frequence, strategy.trade_frequence 来调用 handle
    # handle 判断内容，进行操作
    count = 0
    start_date = Date.strptime(strategy.start_date, Data::DATE_FORMAT)
    end_date = Date.strptime(strategy.end_date, Data::DATE_FORMAT)

    (start_date..end_date).each do |date|
      next unless Data.open_dates.include? date.strftime(Data::DATE_FORMAT)

      count += 1
      if count % strategy.trade_frequency == 0
        account.current_date = date
        strategy.handle
      end
    end

    # 根据 strategy 生成操作历史，收益情况
    price_date = end_date
    loop do
      break if Data.open_dates.include?(price_date.strftime(Data::DATE_FORMAT))
      price_date = price_date.prev_day
    end
    puts account.history
    puts account.capital(price_date)

    # 用 hs00300 来做 benchmark
    benchmark_data = Data.stock(strategy.benchmark)
    benchmark_result = []
    benchmark_init = nil
    (start_date..end_date).each do |date|
      next unless Data.open_dates.include? date.strftime(Data::DATE_FORMAT)

      object = benchmark_data.find do |o|
        o['tradeDate'] == date.strftime(Data::DATE_FORMAT)
      end

      next if object.nil?

      benchmark_init = object['closeIndex'] if benchmark_init.nil?
      change = (object['closeIndex'] - benchmark_init).to_f / benchmark_init
      benchmark_result << {
        'date' => date.strftime(Data::DATE_FORMAT),
        'change' => change
      }
    end
    puts benchmark_result
  end
end
