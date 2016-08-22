require 'json'
require 'bigdecimal'
require 'forwardable'
require 'parallel'

Dir['./lib/backtest/**/*.rb'].each { |file| require file }

# Backtest namespace
module Backtest
  def self.bundles
  end
end
