require 'test_helper'

describe 'Data' do
  before do
    @data = Backtest::Data.stock('600036')
  end

  it 'test store data' do
    assert @data.is_a?(Array)
  end
end
