module Backtest
  # for account
  class Account
    attr_accessor :current_date
    attr_accessor :history

    def initialize(init_capital)
      @init_capital = init_capital
      @cash = init_capital
      @holdings = Hash.new(0)
      @history = []
    end

    # 正数的 amount 代表买入，负数的 amount 代表卖出
    # 需要考虑是否是涨停，跌停
    def order(code, amount)
      price_date = current_date.next
      object = nil

      loop do
        if Data.open_dates.include? price_date.strftime(Data::DATE_FORMAT)
          object = Data.stock(code).find do |o|
            o['date'] == price_date.strftime(Data::DATE_FORMAT)
          end
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
          total_price: total_price,
          trade_at: current_date.strftime(Data::DATE_FORMAT),
          cash: @cash,
          holdings: @holdings.dup
        }
      elsif amount < 0 && @holdings[code] + amount >= 0
        # 需要卖出，并且有足够的持仓可以卖出
        @cash -= total_price
        @holdings[code] += amount
        @history << {
          code: code,
          amount: amount,
          price: price,
          total_price: total_price,
          trade_at: current_date.strftime(Data::DATE_FORMAT),
          cash: @cash,
          holdings: @holdings.dup
        }
      end
    end

    def capital(date)
      worth = 0

      prev_trades = @history.find_all do |trade|
        Date.strptime(trade[:trade_at], Data::DATE_FORMAT) <= date
      end
      unless prev_trades.empty?
        trade = prev_trades.last
        price_date = date
        loop do
          break if Data.open_dates.include?(price_date.strftime(Data::DATE_FORMAT))
          price_date = price_date.prev_day
        end
        trade[:holdings].each_pair do |code, amount|
          price_object = Data.stock(code).find do |o|
            o['date'] == price_date.strftime(Data::DATE_FORMAT)
          end
          price = BigDecimal.new(price_object['open'].to_s)
          worth += price * amount
        end
        {
          cash: trade[:cash],
          holdings: trade[:holdings],
          worth: trade[:cash] + worth
        }
      else
        {
          cash: @init_capital,
          holdings: {},
          worth: @init_capital
        }
      end
    end
  end
end
