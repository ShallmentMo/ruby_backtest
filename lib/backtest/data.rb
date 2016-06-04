module Backtest
  # Generator backtest data from different source
  # Now only support json file
  # use for fetch data
  module Data
    DATE_FORMAT = '%F'.freeze

    def self.universe
      @universe ||= Hash.new({})
    end

    def self.stock(code)
      return universe['stock'][code] if universe['stock'][code]
      file = File.new("./lib/#{code}.json")
      universe['stock'][code] = JSON.parse(file.readline)
    end

    def self.calendar
      @calendar ||= JSON.parse(File.new('./lib/trade_calendar.json').readline)
                        .map do |object|
                          {
                            'date' => Date.strptime(object['date'], '%Y/%m/%e')
                                          .strftime(DATE_FORMAT),
                            'is_open' => object['is_open']
                          }
                        end
    end

    def self.open_dates
      @open_dates ||= calendar.select { |object| object['is_open'] == '1' }
                              .map { |object| object['date'] }
    end

    def self.k_lines(data)
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
