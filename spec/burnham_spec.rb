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
      rows_function = Proc.new { |model, frame| 
        frame.create_row(:period_start, 'Start of Period', Proc.new { |model, frame, row, column_key| 
          Date.new(2023,9,1) >> (frame[:header][column_key]+1)
        })
        frame.create_row(:period_start, 'End of Period', Proc.new { |model, frame, row, column_key| 
          Date.new((frame[:period_start][column_key] >> 1) - 1)
        })        
      }
      @frame_one = @model.create_frame(:frame_one, 'Frame One',Proc.new { [1,2,3,4,5,6,7,8,9,10] }, rows_function )
       
      @model.run

      print @frame_one.to_s
    end
  end
end