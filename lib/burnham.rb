# frozen_string_literal: true

require_relative "burnham/version"

module Burnham
  class Model
    attr_reader :frames, :name

    def initialize(name)
      @name=name
      @frames = Hash.new
      @rows = Hash.new
    end

    def create_frame(ref, name, columns_setup_function, rows_setup_function)
      frame = Frame.new(ref, name, self, columns_setup_function, rows_setup_function)
      @frames[frame.ref] = frame
      frame
    end

    def register_row(row)
      @rows[row.ref] = row
    end

    def run()
      @frames.each { |frame_ref, frame| frame.setup }
      @rows.each { |row_ref, row| row.run }
    end
  end

  # Has a fixed number of columns and a header row with values calculated during setup phase
  # Has a number of Rows
  # Has a setup phase and a run phase
  # Has a setup function which creates the header row and the Row definitions
  # Has a run function which runs each Row function
  class Frame
    attr_reader :ref, :name, :model
    attr_reader :rows, :columns

    def initialize(ref, name, model, columns_setup_function, rows_setup_function)
      @ref = ref
      @name = name
      @model = model
      @columns_setup_function = columns_setup_function
      @rows_setup_function = rows_setup_function
      @rows = Hash.new
    end

    def to_s
      "\n Header: " + @columns.to_s + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("/n")
    end

    def create_row(ref, name, run_function)
      row = Row.new(ref, name, self, run_function)
      @rows[row.ref] = row
      @model.register_row(row)
    end

    def setup()
      @columns = Hash[@columns_setup_function.call(model, self).map.with_index {|val,indx| [val, indx]}]
      @rows_setup_function.call(model, self)
    end

    def is_setup
      @colums.length > 0
    end

    def [](row_ref)
      if row_ref==:header
        @columns
      else 
        @rows[row_ref]
      end
    end
  end

  class Row
    attr_reader :ref, :name, :frame, :is_run
    def initialize(ref, name, frame, run_function)
      @ref = ref
      @name = name
      @frame = frame
      @run_function = run_function
      @is_run = false
      @cells = []
    end

    def to_s
      @ref.to_s + ':' + @name + ' ' + @values.join(',')
    end

    def [] (column_ref)
      @cells[@frame.columns[column_ref]].value
    end

    def run
      unless @is_run
        @cells = @frame.columns.map do |column_key, column_index|
          Cell.new()
          @run_function.call(@frame.model, @frame, self, column_key)
        end
        is_run = true
      end
    end
  end

  class Cell
    attr_reader :is_dirty
    attr_reader :frame, :row, :column_ref

    def initialize(frame, row, column_ref, run_function)
      @is_dirty = true
      @run_function = run_function
      @frame = frame
      @row = row
      @column_ref = column_ref
      @value = nil
    end

    def run
      @value = run_function.call(@frame.model, @frame, @row, @column_ref)
      @is_dirty = false
    end

    def value
      @value
    end
  end
end