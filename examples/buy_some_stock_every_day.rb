require File.expand_path('../../lib/backtest', __FILE__)
require 'benchmark'

class BuySomeStockEveryDayStrategy < Backtest::Strategy
  def handle
    order('600036', 100)
  end
end

strategy = BuySomeStockEveryDayStrategy.new(end_date: '2016-04-01', start_date: '2008-01-01', universe: %w(600036), capital: 1_000_000, trade_frequency: 1, benchmark: '000300')

Benchmark.bm do |x|
  x.report do
    Backtest.test strategy
    # puts strategy.account.capital(strategy.start_date, strategy.end_date)
    # puts strategy.benchmark_data
    puts strategy.summary
  end
end
