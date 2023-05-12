# frozen_string_literal: true

require_relative "burnham/version"

module Burnham
  #
  class Model
    attr_reader :frames, :name

    def initialize(name)
      @name=name
      @frames = Hash.new
    end

    def create_frame(ref, name, column_setup_function, row_setup_function)
      frame = Frame.new(ref, name, self, column_setup_function, row_setup_function)
      @frames[frame.ref] = frame
      frame
    end

    def run()

    end
  end

  # Has a fixed number of columns and a header row with values calculated during setup phase
  # Has a number of Rows
  # Has a setup phase and a run phase
  # Has a setup function which creates the header row and the Row definitions
  # Has a run function which runs each Row function
  class Frame
    attr_reader :ref, :name, :model, :rows

    attr_reader :row_count

    def initialize(ref, name, model, column_setup_function, row_setup_function)
      @ref = ref
      @name = name
      @model = model
      @column_setup_function = column_setup_function
      @row_setup_function = row_setup_function
      @rows = Hash.new
      @columns = nil
    end

    def create_row(ref, name, run_function)
      row = Row.new(ref, name, self, run_function)
      @rows[row.ref] = row
    end

    def setup()
      @columns = @column_setup_function.call(model, self)
      @row_setup_function.call(model, self)
    end
    def run()

    end

    def [](row_ref)
      @rows[row_ref]
    end
  end

  class Row
    attr_reader :ref, :name, :frame
    def initialize(ref, name, frame, run_function)
      @ref = ref
      @name = name
      @frame = frame
      @run_function = run_function
    end
  end
end

