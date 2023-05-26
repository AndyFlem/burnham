module Burnham
  class Context
    attr_reader :column_number, :column_ref
    def initialize(row, column_ref, column_number)
      #@cell = cell
      @column_number = column_number
      @column_ref = column_ref
      @row = row
    end

    # {:table, :row} or :row
    def row(*args)
      row_ref = if args[0].class == Hash
        table_ref = args[0][:table] if args[0].has_key?(:table)
        args[0][:row]
      else
        args[0]
      end

      if table_ref.nil?
        table = @row.table
      else
        raise RuntimeError.new("Table '#{table_ref.to_s}' not found.") unless @row.model.tables.has_key?(table_ref)
        table = @row.model.tables[table_ref]
      end
      raise RuntimeError.new("Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(row_ref)
      row = table.rows[row_ref]
      row.register_dependent(@row)
      row
    end

    # {:table, :row, :column} or :row
    def cell(*args)
    
      if args[0].class == Hash
        table_ref = args[0][:table] if args[0].has_key?(:table)
        row_ref = args[0][:row] if args[0].has_key?(:row)
        column_ref = args[0][:column] if args[0].has_key?(:column)
        column_offset = args[0][:column_offset] if args[0].has_key?(:column_offset)
      else
        row_ref = args[0]
        column_ref = args[1] if args.length>1
        table_ref = args[2] if args.length>2
      end

      if table_ref.nil?
        table = @row.table
      else
        table = @row.model.tables[table_ref]
      end

      if row_ref.nil?
        row = @row
      else
        raise RuntimeError.new("Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(row_ref)
        row = table.rows[row_ref]
      end
      
      row.register_dependent(@row)

      if table.is_list
        row.cells[0]
      else
        if column_ref.nil?
          col = column_number + (column_offset.nil? ? -1 : column_offset-1)
          row.cells[col] if col>=0
        else
          raise RuntimeError.new("Column '#{column_ref.to_s}' not found in table '#{table.ref.to_s}'.") unless table.columns.has_key?(column_ref)
          row.cells[table.columns[column_ref]-1]
        end
      end
    end
    alias [] cell

    def lookup(args) # return_row, lookup, lookup_row, table
      raise ArgumentError.new("Arguments error (require at least :lookup and :return_row):#{args}.") unless args.has_key?(:return_row) and args.has_key?(:lookup)  
      table = if args.has_key?(:table)
        @row.model.tables[args[:table]]
      else
        @cell.table
      end

      raise ArgumentError.new("Row '#{return_row.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(args[:return_row])

      if args.has_key?(:lookup_row)
        lookup_row = args[:lookup_row]
        raise ArgumentError.new("Row '#{lookup_row.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(lookup_row)

        row = table.rows[lookup_row]
        row.register_dependent(@row)
        indx = row.cells.find_index(args[:lookup])
        raise RuntimeError.new("Value '#{args[:lookup]}' not found in row '#{row.ref.to_s}'.") if indx.nil?        
      else
        raise RuntimeError.new("Value '#{args[:lookup]}' not found in columns for table '#{table.ref.to_s}'.") unless table.columns.has_key?(args[:lookup])
        indx = table.columns[args[:lookup]]
      end
      table.rows[args[:return_row]].column(indx)
    end
  end
end