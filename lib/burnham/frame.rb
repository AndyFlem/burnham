module Burnham
  class Frame
    attr_reader :ref, :name, :model, :is_setup
    attr_reader :rows, :columns, :is_list

    def initialize(ref, name, model, columns_definition, rows_definition)
      @ref = ref
      @name = name
      @model = model
      @columns_definition = columns_definition
      @rows_definition = rows_definition
      @rows = Hash.new
      @is_list = false
    end

    def to_s
      "\n" + @ref.to_s + ':' + @name + (@is_list ? '' : ' ' + @columns.keys.join(',') ) + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("")
    end

    def create_row(ref, name, cell_function)
      row = Row.new(ref, name, self, cell_function)
      @rows[row.ref] = row
      @model.register_row(row)
    end

    def setup()
      unless @is_setup
        print "\nFrame setup (#{@ref.to_s})...."

        columns_array = case @columns_definition
        when Proc
          @columns_definition.call(self)
        when NilClass
          @is_list = true
          [:value]
        else
          @columns_definition
        end

        @columns = Hash[columns_array.map.with_index {|val,indx| [val, indx]}]

        @rows_definition.each { |row_definition| 
          create_row(row_definition[0], row_definition[1], row_definition[2])
        }
        @rows.each {|row_ref, row| row.setup}

        @is_setup = true

        print "done.\n"
      end
    end

    def [](row_ref)
      setup unless @is_setup

      row = if row_ref==:header
        @columns
      else
        if @rows.has_key?(row_ref)
          @rows[row_ref]
        else
          raise "Row '#{row_ref.to_s}' not found in frame '#{@ref.to_s}'."
        end
      end

      @is_list ? row.cells[0].value : row
    end
  end
end