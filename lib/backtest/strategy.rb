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
      days = Date.strptime(end_date) - Date.strptime(start_date)

      # 计算年化收益率 annualized_returns
      capital_at_last_date = capitals.last
      earnings = capital_at_last_date[:worth] - capital
      annualized_returns = (earnings / capital) / days * 365

      # 计算基准年化收益率 benchmark_annualized_returns
      earnings_of_benchmark =
        benchmark_data.last['close'] - benchmark_data.first['open']
      benchmark_annualized_returns =
        (earnings_of_benchmark / benchmark_data.first['open']) / days * 365

      # 计算收益波动率 volatility
      sum_of_daily_returns = 0
      capitals.each_with_index do |object, index|
        if index == 0
          object[:daily_returns] = 0
          next
        end

        prev_object = capitals[index - 1]
        daily_returns =
          (object[:worth] - prev_object[:worth]) / prev_object[:worth]
        sum_of_daily_returns += daily_returns
        object[:daily_returns] = daily_returns
      end
      average_of_daily_returns = sum_of_daily_returns / days
      variance_of_daily_returns = capitals.reduce(0) do |memo, object|
        memo + (object[:daily_returns] - average_of_daily_returns)**2
      end
      volatility = Math.sqrt(365 / (days - 1) * variance_of_daily_returns)

      {
        annualized_returns: annualized_returns.to_f.round(4),
        benchmark_annualized_returns:
          benchmark_annualized_returns.to_f.round(4),
        volatility: volatility.round(4)
      }
    end
  end
end
