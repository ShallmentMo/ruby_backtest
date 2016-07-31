module Backtest
  # for strategy
  class Strategy
    extend Forwardable
    attr_reader :start_date, :end_date, :frequency, :trade_frequency, :capital,
                :universe, :benchmark
    attr_accessor :account, :benchmark_data
    def_delegator :account, :order

    def initialize(start_date: Date.today.prev_year.strftime('%F'),
                   end_date: Date.today.strftime('%F'),
                   benchmark: nil, universe: [], capital: 10_000,
                   frequency: 'd', trade_frequency: 1)
      @start_date = start_date
      @end_date = end_date
      @benchmark = benchmark
      @universe = universe
      @capital = capital
      @frequency = frequency
      @trade_frequency = trade_frequency
    end

    def summary
      capitals = account.capital(start_date, end_date)
      days = benchmark_data.size
      filtered_capitals = capitals.select do |object|
        Data.open_dates.include? object[:date]
      end
      # 这里用的无风险利率是一年期定存利率 1.5%
      returns_ratio_of_no_risk = 0.015


      # 计算年化收益率 annualized_returns
      capital_at_last_date = filtered_capitals.last
      earnings = capital_at_last_date[:worth] - capital
      annualized_returns = (earnings / capital) / days * 250

      # 计算基准年化收益率 benchmark_annualized_returns
      earnings_of_benchmark =
        benchmark_data.last['close'] - benchmark_data.first['open']
      benchmark_annualized_returns =
        (earnings_of_benchmark / benchmark_data.first['open']) / days * 250

      # 计算收益波动率 volatility
      sum_of_daily_returns = 0
      filtered_capitals.each_with_index do |object, index|
        if index == 0
          object[:daily_returns] = 0
          next
        end

        prev_object = filtered_capitals[index - 1]
        daily_returns =
          (object[:worth] - prev_object[:worth]) / 1_000_000
        sum_of_daily_returns += daily_returns
        object[:daily_returns] = daily_returns
      end
      average_of_daily_returns = sum_of_daily_returns / days
      quadratic_sum_of_daily_returns = filtered_capitals.reduce(0) do |memo, object|
        memo + (object[:daily_returns] - average_of_daily_returns)**2
      end
      volatility = Math.sqrt(250 / (days - 1) * quadratic_sum_of_daily_returns)

      # 计算夏普比率 sharpe_ratio
      sharpe_ratio = (annualized_returns - returns_ratio_of_no_risk) / volatility

      # 计算贝塔 beta
      sum_of_benchmark_daily_returns = 0
      sum_of_product_of_daily_returns_and_benchmark_daily_returns = 0
      benchmark_data.each_with_index do |object, index|
        if index == 0
          object['daily_returns'] = 0
          next
        end

        prev_object = benchmark_data[index - 1]
        benchmark_daily_returns =
          (object['close'] - prev_object['close']) / prev_object['close']
        sum_of_daily_returns += benchmark_daily_returns
        object['daily_returns'] = benchmark_daily_returns
        daily_returns_of_capitals = filtered_capitals.find do |capital|
          capital[:date] == object['date']
        end[:daily_returns]
        sum_of_product_of_daily_returns_and_benchmark_daily_returns +=
          benchmark_daily_returns * daily_returns_of_capitals
      end
      average_of_benchmark_daily_returns =
        sum_of_benchmark_daily_returns / days
      average_of_product_of_daily_returns_and_benchmark_daily_returns =
        sum_of_product_of_daily_returns_and_benchmark_daily_returns / days
      covariance_of_daily_returns_and_benchmark_daily_returns =
        average_of_product_of_daily_returns_and_benchmark_daily_returns - average_of_daily_returns * average_of_benchmark_daily_returns
      variance_of_benchmark_daily_returns = benchmark_data.reduce(0) do |memo, object|
        memo + (object['daily_returns'] - average_of_benchmark_daily_returns)**2
      end / days
      beta =
        covariance_of_daily_returns_and_benchmark_daily_returns / variance_of_benchmark_daily_returns

      # 计算阿尔法 alpha
      alpha = annualized_returns - returns_ratio_of_no_risk -
              beta * (benchmark_annualized_returns - returns_ratio_of_no_risk)

      # 计算信息比率 information_ratio
      standard_deviation_of_daily_returns_and_benchmark_daily_returns =
        Math.sqrt(benchmark_data.reduce(0) do |memo, object|
          daily_returns_of_capitals = filtered_capitals.find do |capital|
            capital[:date] == object['date']
          end[:daily_returns]
          memo + (object['daily_returns'] - daily_returns_of_capitals)**2
        end / days)
      information_ratio =
        (annualized_returns - benchmark_annualized_returns) / standard_deviation_of_daily_returns_and_benchmark_daily_returns

      # 计算最大回撤 max_drawdown
      filtered_capitals.each do |object|
        object_with_minimum_worth_after_object = filtered_capitals.select do |capital|
          Date.strptime(capital[:date], '%F') > Date.strptime(object[:date], '%F')
        end.min_by do |capital|
          capital[:worth]
        end
        if object_with_minimum_worth_after_object
          object[:drawdown] =
            1 - object[:worth] / object_with_minimum_worth_after_object[:worth]
        end
      end
      max_drawdown = filtered_capitals.select do |capital|
        capital[:drawdown]
      end.max_by do |capital|
        capital[:drawdown]
      end[:drawdown]

      {
        annualized_returns: annualized_returns.to_f.round(4),
        benchmark_annualized_returns:
          benchmark_annualized_returns.to_f.round(4),
        sharpe_ratio: sharpe_ratio.to_f.round(4),
        volatility: volatility.round(4),
        beta: beta.to_f.round(4),
        alpha: alpha.to_f.round(4),
        information_ratio: information_ratio.to_f.round(4),
        max_drawdown: max_drawdown.to_f.round(4)
      }
    end
  end
end
