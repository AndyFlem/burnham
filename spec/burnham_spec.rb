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

      @periods = @model.create_frame(:periods, 'Periods', Proc.new { 1..@model[:params][:periods]['Value'] }, [ 
        [:period_end, 'End of Period', Proc.new { |frame, row, column_key| 
          (frame[:period_start][column_key] >> 1) - 1
        }],
        [:period_start, 'Start of Period', Proc.new { |frame, row, column_key| 
          @params[:start_date]['Value'] >> (frame[:header][column_key]+1)
        }]
      ])
      
      @params = @model.create_frame(:params, 'Parameters', ['Value'], [
        [:start_date,'Model Start Date', Date.new(2023,9,1)],
        [:periods,'Number of Periods', 20]
      ])

      @model.run

      print @params.to_s
      print @periods.to_s
    end
  end
end