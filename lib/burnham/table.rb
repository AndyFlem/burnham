module Burnham
  class Table
    attr_reader :ref, :name, :model
    attr_reader :rows, :is_list, :columns

    def initialize(ref, name, model, columns = [:value], &block)
      @ref = ref
      @name = name
      @model = model
      @rows = Hash.new
      @columns = Hash[columns.map.with_index {|key, i| [key, i]}]
      @is_list = true if columns.length == 1
      yield (self) if block_given?
    end

    def to_s
      "\n" + @ref.to_s + ':' + @name + "\n" + @columns.to_s + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("")
    end

    # args : last hash is metadata, last argument is vals
    def row(ref, name, *args, &block)
      raise ArgumentError.new("Existing row with ref: " + ref.to_s) if @rows.has_key?(ref)
      vals = nil
      metadata = nil
      args.each do |arg| 
        if arg.class == Hash
          metadata = arg 
        else
          vals = arg
        end
      end
      block = nil if not (vals.nil? or block.nil?)

      unless @columns.length==1 or vals.nil?
        raise ArgumentError.new("Values must be supplied for all rows (#{@columns.length}).") if vals.length != @columns.length
      end

      row = Row.new(ref, name, metadata, self, vals, block)
      @rows[row.ref] = row
      @model.register_row(row)
    end

    def [](row_ref)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @is_list ? @rows[row_ref].cells[0] : @rows[row_ref]
    end

    def []=(row_ref, new_values)
      raise ArgumentError.new("Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'.") unless @rows.has_key?(row_ref)
      @rows[row_ref].values=new_values
    end
    
  end
end
