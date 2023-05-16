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
      
      #@params = @model.create_frame(:frame_one, 'Frame One',Proc.new { [1,2,3,4,5,6,7,8,9,10] }, Proc.new { |model, frame| 

      @periods = @model.create_frame(:frame_one, 'Frame One',Proc.new { [1,2,3,4,5,6,7,8,9,10] }, [ 
        {row_ref: :period_end, row_name: 'End of Period', values: Proc.new { |model, frame, row, column_key| 
          (frame[:period_start][column_key] >> 1) - 1
        }},

        {row_ref: :period_start, row_name: 'Start of Period', values: Proc.new { |model, frame, row, column_key| 
          Date.new(2023,9,1) >> (frame[:header][column_key]+1)
        }}
      ])
      
      
      @model.run

      print @frame_one.to_s
    end
  end
end