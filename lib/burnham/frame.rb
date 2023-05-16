
module Burnham
    class Frame
      attr_reader :ref, :name, :model
      attr_reader :rows, :columns
  
      def initialize(ref, name, model, columns_definition, rows_definition)
        @ref = ref
        @name = name
        @model = model
        @columns_definition = columns_definition
        @rows_definition = rows_definition
        @rows = Hash.new
      end
  
      def to_s
        "\n Header: " + @columns.to_s + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("")
      end
  
      def create_row(ref, name, cell_function)
        row = Row.new(ref, name, self, cell_function)
        @rows[row.ref] = row
        @model.register_row(row)
      end
  
      def setup()
        @columns = Hash[@columns_definition.call(model, self).map.with_index {|val,indx| [val, indx]}]
        @rows_setup_function.call(model, self)
        @rows.each {|row_ref, row| row.setup}
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

  end