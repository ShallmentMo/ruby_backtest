module Backtest
  # Generator backtest data from different source
  # Now only support json file
  class DataGenerator
    attr_reader :data

    def initialize(path)
      file = File.new(path)
      @data = JSON.parse(file.readline)
    end

    def k_lines
      return @k_lines unless @k_lines.nil?

      dates = data.map { |object| object['date'] }
      datum = data.map do |object|
        [object['open'], object['low'], object['high'], object['close']]
      end
      datasets = ::GnuplotRB::Dataset.new([dates, datum], using: '1:2:3:4:5',
                                                          with: 'candlesticks')
      @k_lines = ::GnuplotRB::Plot.new(
        *datasets,
        with: 'candlesticks',
        timefmt: '%Y-%m-%d',
        xdata: 'time',
        terminal: "png size #{dates.size * 3}"
      )
    end
  end
end
