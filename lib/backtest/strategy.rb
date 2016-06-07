module Backtest
  # for strategy
  class Strategy
    extend Forwardable
    attr_reader :start_date, :end_date, :frequency, :trade_frequency, :capital,
                :universe, :benchmark
    attr_accessor :account

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

    def_delegator :account, :order
  end
end
