require 'test_helper'

class BacktestTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Backtest::VERSION
  end
end
