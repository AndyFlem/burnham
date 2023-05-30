# frozen_string_literal: true
require 'date'
require 'descriptive_statistics'

require_relative "burnham/version"
require_relative "burnham/model"
require_relative "burnham/table"
require_relative "burnham/row"
require_relative "burnham/context"

class Array
  def rollup(group_function, &block_given)
    (group group_function).each_value do |group|
      yield group
    end
  end 
end