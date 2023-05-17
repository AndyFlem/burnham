require_relative '../lib/burnham'
require 'date'

module Burnham
  RSpec.describe Model do
    it "allows the creation of a new model" do
      model = Model.new('Test Model')
      expect(model.name).to eq('Test Model')
    end
  end

  RSpec.describe Model do
    before(:all) do 
      @model = Model.new('Test Model')
    end
    it "allows the creation of a new frame" do

      @periods = @model.create_frame(:periods, 'Periods', Proc.new { 1..@model[:params][:periods] }, [ 
        [:period_end, 'End of Period', Proc.new { |frame, row, column| 
          (frame[:period_start][column] >> 1) - 1
        }],
        [:period_start, 'Start of Period', Proc.new { |frame, row, column| 
          @params[:start_date] >> (frame[:header][column]+1)
        }],
        [:rand, 'Random', Proc.new { |frame, row, column| 
          rand()
        }]
        [:rand_agg, 'Aggregate of Random', Proc.new { |frame, row, column, column_number|
          (0...column_number).each {|i| frame[:rand][]}
        }]
      ])
      
      @params = @model.create_list(:params, 'Parameters', [
        [:start_date,'Model Start Date', Date.new(2023,9,1)],
        [:twice_periods,'Twice Number of Periods', Proc.new { |frame| frame[:periods] * 2 }],
        [:periods,'Number of Periods', 20],
      ])

      @model.run

      print @params.to_s
      print @periods.to_s
    end
  end
end