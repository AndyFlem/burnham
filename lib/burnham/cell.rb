
module Burnham
    class Cell
      attr_reader :is_dirty
      attr_reader :frame, :row, :column_ref
  
      def initialize(frame, row, column_ref, cell_function)
        @is_dirty = true
        @cell_function = cell_function
        @frame = frame
        @row = row
        @column_ref = column_ref
        @value = nil
      end
  
      def run
        if @is_dirty
          @value = @cell_function.call(@frame.model, @frame, @row, @column_ref)
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