require 'json'
require 'gnuplotrb'
require 'bigdecimal'

Dir['./lib/backtest/*.rb'].each { |file| require file }

# Backtest namespace
module Backtest
  def self.test(strategy)
    $universe = {}
    strategy.universe.each do |code|
      $universe[code] = DataGenerator.generate(code)
    end

    # 获取开市日期，现在是从 json 文件导入，以后可以考虑使用 tushare-ruby
    # "isOpen" 为 1 的日子是开市
    $calendar = JSON.parse(File.new('./lib/trade_calendar.json').readline)
    $dates = $calendar.select { |date| date['is_open'] == '1' }
                      .map { |date| date['date'].tr('/', '-') }

    # 初始化账户金额
    account = Account.new(strategy.capital)
    strategy.account = account

    # 从 strategy.start_date 迭代到 strategy.end_date
    # 需要判断是否是开市的日子
    # 需要根据 strategy.frequence, strategy.trade_frequence 来调用 handle
    # handle 判断内容，进行操作
    count = 0
    start_date = Date.strptime(strategy.start_date, '%F')
    end_date = Date.strptime(strategy.end_date, '%F')
    (start_date..end_date).each do |date|
      next unless $dates.include? date.strftime('%Y-%-m-%e')

      count += 1
      if count % strategy.trade_frequency == 0
        account.current_date = date.strftime('%F')
        strategy.handle
      end
    end

    # 根据 strategy 生成操作历史，收益情况
    price_date = end_date
    loop do
      break if $dates.include?(price_date.strftime('%Y-%-m-%e'))
      price_date = price_date.prev_day
    end
    puts account.history
    puts account.capital(price_date)
  end
end
