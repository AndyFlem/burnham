require_relative '../lib/burnham'

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
      @frame_one = @model.create_frame(:frame_one, name: 'Frame One', 
        { |model, frame|
          [1,2,3,4,5,6,7,8,9,10]
        }
      )
    end
  end

end