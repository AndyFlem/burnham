module Burnham
  class Table
    attr_reader :ref, :name, :model
    attr_reader :rows, :index

    def initialize(ref, name, model, &block)
      @ref = ref
      @name = name
      @model = model
      @rows = Hash.new
      @index = nil
      yield (self) if block_given?
    end

    def to_s
      "\n" + @ref.to_s + ':' + @name + " - " + @rows.count.to_s + " rows x " + @index.to_a.count.to_s + "\n" + @rows.map do |row_ref, row|  
        row.to_s + "\n" unless row.hidden
      end.join("")
    end

    # create a row with a block that returns a vals array
    def row(*args, &block)
      if args[0].class == Hash
        ref=args[0][:ref]
        name=args[0][:name]
        metadata=args[0][:metadata]
        not_index_dependent = args[0][:not_index_dependent]
        not_index = args[0][:not_index]
        hidden = args[0][:hidden]
        format = args[0][:format]
      else
        ref = args[0]
        name = args[1]
      end
      raise ArgumentError.new("Existing row with ref: " + ref.to_s) if @rows.has_key?(ref)
      raise ArgumentError.new("Must provide a formula for row: " + ref.to_s) if (not block_given?)

      is_index = @index.nil? unless not_index

      row = Row.new()
      row.new_row(ref, name, metadata, self, is_index, not_index_dependent, hidden, block)
      @index = row if is_index
      @rows[row.ref] = row
      @model.register_row(row)      
    end

    # create a row with a values array or a function called against each cell
    def cells(*args, &block)
      vals = nil
      if args[0].class == Hash
        ref=args[0][:ref]
        name=args[0][:name]
        vals=args[0][:values]
        metadata=args[0][:metadata]
        hidden = args[0][:hidden]
      else
        ref = args[0]
        name = args[1]
        vals = args[2]
      end
      
      vals=vals.to_a if vals.class == Range

      raise ArgumentError.new("Existing row with ref: " + ref.to_s) if @rows.has_key?(ref)
      raise ArgumentError.new("Can only provide values or a formula for row: " + ref.to_s) if (not vals.nil?) and block_given?
      raise ArgumentError.new("Must provide values or a formula for row: " + ref.to_s) if (vals.nil? and not block_given?)

      is_index = @index.nil? unless vals.nil?

      row = Row.new()
      row.new_cells(ref, name, metadata, self, is_index, hidden, vals, block)
      @index = row if is_index
      @rows[row.ref] = row
      @model.register_row(row)
    end

    def is_list
      raise RuntimeError.new("Table not built.") if @index.nil?
      @index.values.length == 1
    end

    def width
      raise RuntimeError.new("Table not built.") if @index.nil?
      @index.length
    end

    def index_of(column_ref)
      raise RuntimeError.new("Table not built.") if @index.nil?
      @index.find_index(column_ref)
    end

    def height
      @rows.length
    end

    def [](row_ref)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @index.length == 1 ? @rows[row_ref].cells[0] : @rows[row_ref]
    end

    def []=(row_ref, new_values)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @rows[row_ref].values=new_values
    end
    
    def column(column_number)
      @rows.values.map {|r| r.column(column_number)}  
    end

    def column_to_s(column_number)
      @rows.values.map {|r| r.name}.zip(column(column_number)).map {|r| r[0] + ': ' + r[1].to_s}.join(', ')
    end

    def columns
      (@rows.values.select {|v| not v.hidden}.map(&:to_a)).transpose
    end
  end
end
