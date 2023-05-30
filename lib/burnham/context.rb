module Burnham
  class Context
    #attr_reader :row
    def initialize(context_row)
      @rw = context_row
    end

    # {:table, :row, :column, :column_number} or :row
    # return a single cell from address
    def cell(args)
      if args.class == Hash
        table_ref = args[:table] if args.has_key?(:table)
        row_ref = args[:row] if args.has_key?(:row)
        column_ref = args[:column] if args.has_key?(:column)
        column_number = args[:column_number] if args.has_key?(:column_number)
      else
        row_ref = args
      end

      if table_ref.nil?
        table = @rw.table
      else
        table = @rw.model.tables[table_ref]
      end

      column_number = 0 if table.width == 1

      if row_ref.nil?
        sel_row = @rw
      else
        raise RuntimeError.new("Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(row_ref)
        sel_row = table.rows[row_ref]
      end
      
      sel_row.register_dependent(@rw)
      if column_number>=0
        sel_row.cells[column_number] 
      else
        nil 
      end
    end

    # return a single cell by lookup
    def lookup(args) # table, lookup, lookup_row, return_row
      raise ArgumentError.new("Arguments error (require at least :lookup and :return_row):#{args}.") unless args.has_key?(:return_row) and args.has_key?(:lookup)  
      table = if args.has_key?(:table)
        @rw.model.tables[args[:table]]
      else
        @rw.table
      end
      raise ArgumentError.new("Row '#{args[:return_row].to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(args[:return_row])

      if args.has_key?(:lookup_row)
        lookup_row = args[:lookup_row]
        raise ArgumentError.new("Row '#{lookup_row.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(lookup_row)

        sel_row = table.rows[lookup_row]
        sel_row.register_dependent(@rw)
        indx = sel_row.index_of(args[:lookup])
        raise RuntimeError.new("Value '#{args[:lookup]}' not found in row '#{sel_row.ref.to_s}'.") if indx.nil?        
      else
        indx = table.index.index_of(args[:lookup])
        raise RuntimeError.new("Value '#{args[:lookup]}' not found in columns for table '#{table.ref.to_s}'.") if indx.nil?
      end

      table.rows[args[:return_row]].column(indx)
    end

    #return a row
    # {:table, :row} or :row
    def [](args)
      if args.class == Hash
        table_ref = args[:table] if args.has_key?(:table)
        row_ref = args[:row]
      else
        row_ref = args
      end

      if table_ref.nil?
        table = @rw.table
      else
        raise RuntimeError.new("Table '#{table_ref.to_s}' not found.") unless @rw.model.tables.has_key?(table_ref)
        table = @rw.model.tables[table_ref]
      end
      raise RuntimeError.new("Row '#{row_ref.to_s}' not found in table '#{table.ref.to_s}'.") unless table.rows.has_key?(row_ref)
      sel_row = table.rows[row_ref]
      sel_row.register_dependent(@rw)
      sel_row.to_a
    end

  end

  class CellContext < Context
    attr_reader :column_number

    def initialize(context_row, column_number)
      @column_number = column_number
      super context_row
    end

    def row(args)
      Context.instance_method(:[]).bind(self).call(args)
    end

    # {:row, [:table], [:column_number or :column_ref or :column_offset]}
    # if no :column_number or :column_ref or a :column_offset given then use current column
    # return a single cell from address
    def [](args)
      #puts args
      column_no = nil
      if (not args.class==Hash) or (not (args.has_key?(:column_number) or args.has_key?(:column_ref)))
        column_no=@column_number
      else
        column_no = args[:column_number] if args.has_key?(:column_number)
        column_no = row.table.index_of(args[:column_ref]) if args.has_key?(:column_ref)
      end
      raise ArgumentError.new("Cant determine row " + args.to_s) if column_no.nil?
      raise ArgumentError.new("Invalid column #{args.to_s}.") if column_no<0 or column_no > (@rw.table.width-1)
      
      if args.class==Hash
        args[:column_number] = column_no
      else
        args = {column_number: column_no, row: args}
      end
      #puts args
      cell(args)
    end
  end
end