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
      "\n" + @ref.to_s + ':' + @name + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("")
    end

    # create a row with a block that returns a vals array
    def row(*args, &block)
      if args[0].class == Hash
        ref=args[0][:ref]
        name=args[0][:name]
        metadata=args[0][:metadata]
        not_index_dependent = args[0][:not_index_dependent]
        not_index = args[0][:not_index]
      else
        ref = args[0]
        name = args[1]
      end
      raise ArgumentError.new("Existing row with ref: " + ref.to_s) if @rows.has_key?(ref)
      raise ArgumentError.new("Must provide a formula for row: " + ref.to_s) if (not block_given?)

      is_index = @index.nil? unless not_index

      row = Row.new()
      row.new_row(ref, name, metadata, self, is_index, not_index_dependent, block)
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
      else
        ref = args[0]
        name = args[1]
        vals = args[2]
      end
      
      vals=vals.to_a if vals.class == Range

      raise ArgumentError.new("Existing row with ref: " + ref.to_s) if @rows.has_key?(ref)
      raise ArgumentError.new("Can only provide values or a formula for row: " + ref.to_s) if (not vals.nil?) and block_given?
      raise ArgumentError.new("Must provide values or a formula for row: " + ref.to_s) if (vals.nil? and not block_given?)

      is_index = (@index.nil? and (not vals.nil?))

      row = Row.new()
      row.new_cells(ref, name, metadata, self, is_index, vals, block)
      @index = row if is_index
      @rows[row.ref] = row
      @model.register_row(row)
    end

    #def column(value)
    #  raise RuntimeError.new("Table not built.") unless has_index
    #  @index.index_of(value)
    #end

    def is_list
      raise RuntimeError.new("Table not built.") unless has_index
      @index.values.length == 1
    end

    def width
      raise RuntimeError.new("Table not built.") unless has_index
      @index.length
    end

    def index_of(value)
      raise RuntimeError.new("Table not built.") unless has_index
      @index.find_index(value)
    end


    def height
      @rows.length
    end

    def has_index
      #puts @index.address
      (not @index.nil?) && @index.is_run
    end

    def [](row_ref)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @index.length == 1 ? @rows[row_ref].cells[0] : @rows[row_ref]
    end

    def []=(row_ref, new_values)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @rows[row_ref].values=new_values
    end
    
    def columns
      (@rows.to_a.map {|r| r[1].to_a}).transpose
    end
  end
end
