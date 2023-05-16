module Burnham
  class Cell
    attr_reader :is_dirty
    attr_reader :frame, :row, :column_ref

    def initialize(frame, row, column_ref, cell_value)
      @is_dirty = true
      @cell_value = cell_value
      @frame = frame
      @row = row
      @column_ref = column_ref
      @value = nil
    end

    def run
      if @is_dirty
        @value = case @cell_value
        when Proc
          @cell_value.call(@frame, @row, @column_ref)  
        when Array
          @cell_value[@frame.columns[column_ref]]
        else
          @cell_value
        end
        @is_dirty = false
      end
    end

    def value
      run if @is_dirty
      @value
    end

    def address
      [@frame.ref, @row.ref, @column_ref]
    end

    def to_s
      self.value.to_s
    end
  end
end