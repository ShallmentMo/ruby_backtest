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
      capital_at_last_date = account.capital(start_date, end_date).last
      days = Date.strptime(end_date) - Date.strptime(start_date)
      earnings = capital_at_last_date[:worth] - capital
      annualized_return = (earnings / capital) / days * 365
      {
        annualized_return: annualized_return
      }
    end
  end
end
