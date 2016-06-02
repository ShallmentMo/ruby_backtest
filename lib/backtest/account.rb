module Backtest
  # for account
  class Account
    attr_accessor :current_date
    attr_accessor :history

    def initialize(init_capital)
      @cash = init_capital
      @holdings = Hash.new(0)
      @history = []
    end

    # 正数的 amount 代表买入，负数的 amount 代表卖出
    # 需要考虑是否是涨停，跌停
    def order(code, amount)
      price_date = Date.strptime(current_date, '%F').next
      object = nil

      loop do
        if $dates.include?(price_date.strftime('%Y-%-m-%e'))
          object = $universe[code].find { |o| o['date'] == price_date.strftime('%F') }
          break if object
        end
        price_date = price_date.next
      end
      price = BigDecimal.new("#{object['open']}")
      total_price = price * amount
      if amount > 0 && @cash - total_price >= 0
        # 需要买进，并且有足够的钱支付
        @cash -= total_price
        @holdings[code] += amount
        @history << {
          code: code,
          amount: amount,
          price: price,
          total_price: total_price
        }
      elsif amount < 0 && @holdings[code] + amount >= 0
        # 需要卖出，并且有足够的持仓可以卖出
        @cash -= total_price
        @holdings[code] += amount
        @history << {
          code: code,
          amount: amount,
          price: price,
          total_price: total_price
        }
      end
    end

    def capital(date)
      worth = 0
      @holdings.each_pair do |code, amount|
        object = $universe[code].find { |o| o['date'] == date.strftime('%F') }
        price = BigDecimal.new("#{object['open']}")
        worth += price * amount
      end

      {
        cash: @cash,
        holdings: @holdings,
        worth: worth
      }
    end
  end
end
