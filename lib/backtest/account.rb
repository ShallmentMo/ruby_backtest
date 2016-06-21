module Backtest
  # for account
  class Account
    attr_accessor :current_date, :history

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

    def capital(start_date_string, end_date_string = start_date_string)
      start_date = Date.strptime(start_date_string, Data::DATE_FORMAT)
      end_date = Date.strptime(end_date_string, Data::DATE_FORMAT)
      result = []
      start_trade_date =
        @history.first &&
        Date.strptime(@history.first[:trade_at], Data::DATE_FORMAT)
      next_trade_date = start_trade_date
      next_trade = @history.find do |trade|
        Date.strptime(trade[:trade_at], Data::DATE_FORMAT) == next_trade_date
      end
      holdings_price_data = {}

      (start_date..end_date).each do |date|
        # 如果没有交易历史，或者在交易之前
        (result << {
          date: date.strftime(Data::DATE_FORMAT),
          cash: @init_capital,
          holdings: {},
          worth: @init_capital
        } && next) if @history.first.nil? || date < start_trade_date

        if date < next_trade_date
          worth = 0
          next_trade[:holdings].each_pair do |code, amount|
            unless holdings_price_data[code]
              holdings_price_data[code] = {}
              start_index = Data.stock(code).rindex do |o|
                Date.strptime(o['date'], Data::DATE_FORMAT) <= start_date
              end
              (start_date..end_date).each do |d|
                next_object = Data.stock(code)[start_index + 1]
                start_index += 1 if Date.strptime(next_object['date']) <= d
                holdings_price_data[code][d.strftime(Data::DATE_FORMAT)] =
                  Data.stock(code)[start_index]
              end
            end
            price_object =
              holdings_price_data[code][date.strftime(Data::DATE_FORMAT)]
            price = BigDecimal.new(price_object['open'].to_s)
            worth += price * amount
          end
          result << {
            date: date.strftime(Data::DATE_FORMAT),
            cash: next_trade[:cash],
            holdings: next_trade[:holdings],
            worth: next_trade[:cash] + worth
          }
          next
        end

        if date == next_trade_date
          worth = 0
          next_trade[:holdings].each_pair do |code, amount|
            price_object = Data.stock(code).find_all do |o|
              Date.strptime(o['date'], Data::DATE_FORMAT) <= date
            end.last
            price = BigDecimal.new(price_object['open'].to_s)
            worth += price * amount
          end
          result << {
            date: date.strftime(Data::DATE_FORMAT),
            cash: next_trade[:cash],
            holdings: next_trade[:holdings],
            worth: next_trade[:cash] + worth
          }
          # find next_trade
          next_trade_in_history = @history.find do |trade|
            Date.strptime(trade[:trade_at], Data::DATE_FORMAT) > date
          end
          if next_trade_in_history
            next_trade = next_trade_in_history
            next_trade_date =
              Date.strptime(next_trade[:trade_at], Data::DATE_FORMAT)
          else
            next_trade_date = end_date.next
          end
        end
      end

      result
    end
  end
end
