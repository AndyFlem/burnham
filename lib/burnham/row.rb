module Burnham  
  class Row
    attr_reader :ref, :name, :frame, :is_setup, :cells
    def initialize(ref, name, frame, cell_values)
      @ref = ref
      @name = name
      @frame = frame
      @cell_values = cell_values
      @is_setup = false
      @cells = []
    end

    def to_s
      @ref.to_s + ':' + @name + ' ' + @cells.join(',')
    end

    def [] (column_ref)
      if @frame.columns.has_key?(column_ref)
        @cells[@frame.columns[column_ref]].value
      else
        raise "Column '#{column_ref.to_s}' not found in row '#{@ref.to_s}' of frame '#{@frame.ref.to_s}'."
      end
    end

    def setup
      print " row setup (#{@ref.to_s})."

      unless @is_setup
        @cells = @frame.columns.map do |column_key, column_index|
          Cell.new(@frame, self, column_key, @cell_values)
        end
        is_setup = true
      end
    end

    def run
      @cells.each {|cell| cell.run}
    end
  end
end