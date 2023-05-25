module Burnham
  class Context
    attr_reader :column_number, :column_ref
    def initialize(row, column_ref, column_number)
      #@cell = cell
      @column_number = column_number
      @column_ref = column_ref
      @row = row
    end

    #def column_number
    #  @cell.column_number
    #end
    
    #def column_ref
    #  @cell.column_ref
    #end

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
        raise "Table '#{table_ref.to_s}' not found." unless @row.model.tables.has_key?(table_ref)
        table = @row.model.tables[table_ref]
      end
      raise "Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'." unless table.rows.has_key?(row_ref)
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
        raise "Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'." unless table.rows.has_key?(row_ref)
        row = table.rows[row_ref]
      end
      
      row.register_dependent(@row)

      if table.is_list
        row.cells[0]
      else
        if column_ref.nil?
          row.cells[column_number-1]
        else
          raise "Column '#{column_ref.to_s}' not found in table '#{table.ref.to_s}'." unless table.index.has_key?(column_ref)
          row.cells[table.index[column_ref].column_number-1]
        end
      end
    end
    alias [] cell

    def lookup(args) # return_row, lookup, lookup_row, table
      raise "Arguments error (require at least :lookup and :return_row):#{args}." unless args.has_key?(:return_row) and args.has_key?(:lookup)  
      table = if args.has_key?(:table)
        @row.model.tables[args[:table]]
      else
        @cell.table
      end

      raise "Row '#{return_row.to_s}' not found in table '#{table.ref.to_s}'." unless table.rows.has_key?(args[:return_row])

      if args.has_key?(:lookup_row)
        lookup_row = args[:lookup_row]
        raise "Row '#{lookup_row.to_s}' not found in table '#{table.ref.to_s}'." unless table.rows.has_key?(lookup_row)

        row = table.rows[lookup_row]
        row.register_dependent(@row)
        indx = row.cells.find_index(args[:lookup])
        raise "Value #{args[:lookup]} not found in row '#{row.ref.to_s}'." if indx.nil?        
      else
        indx = table.index[args[:lookup]]
      end
      table.rows[args[:return_row]].column(indx)
    end
  end
end