module Burnham
  class Model
    attr_reader :frames, :name

    def initialize(name)
      @name=name
      @frames = Hash.new
      @rows = Hash.new
    end

    def create_frame(ref, name, columns, rows)
      frame = Frame.new(ref, name, self, columns, rows)
      @frames[frame.ref] = frame
      frame
    end

    def create_list(ref, name, rows)
      create_frame(ref, name, nil, rows)
    end    

    def register_row(row)
      @rows[row.ref] = row
    end

    def [](frame_ref)
      @frames[frame_ref]
    end

    def run()
      @frames.each { |frame_ref, frame| frame.setup }
      @rows.each { |row_ref, row| row.run }
    end
  end  
end