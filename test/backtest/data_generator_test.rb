require 'test_helper'

describe 'DataGenerator' do
  before do
    @dg = Backtest::DataGenerator.new('./test/600036.json')
  end

  it 'test store data' do
    assert @dg.data.is_a?(Array)
  end

  it 'test show k_lines' do
    assert !@dg.k_lines.nil?
  end
end
