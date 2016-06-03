require 'test_helper'

describe 'DataGenerator' do
  before do
    @data = Backtest::DataGenerator.generate('600036')
  end

  it 'test store data' do
    assert @data.is_a?(Array)
  end

  it 'test show k_lines' do
    refute_nil Backtest::DataGenerator.k_lines(@data)
  end
end
