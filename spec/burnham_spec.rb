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
      frame = @model.create_frame(ref: :new_frame, name: 'New Frame')
      expect(frame.name).to eq('New Frame')
      expect(frame.ref).to eq(:new_frame)
      expect(@model.frames[:new_frame].ref).to eq(:new_frame)
    end
  end

  RSpec.describe Frame do
    before(:all) do 
      @model = Model.new('Test Model')
      @frame_one = @model.create_frame(ref: :frame_one, name: 'Frame One')
      @frame_two = @model.create_frame(ref: :new_frame, name: 'Frame Two')
    end
    it "allows the creation of a new frame" do
      frame = @model.create_frame(ref: :new_frame, name: 'New Frame')
      expect(frame.name).to eq('New Frame')
    end
  end  
end