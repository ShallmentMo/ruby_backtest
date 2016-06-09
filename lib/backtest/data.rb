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
  end
end
