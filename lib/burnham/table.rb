module Burnham
  class Table
    attr_reader :ref, :name, :model
    attr_reader :rows, :is_list, :index

    def initialize(ref, name, model, index = [:value], &block)
      @ref = ref
      @name = name
      @model = model
      @rows = Hash.new
      @index = Hash[index.map.with_index {|key, i| [key, i]}]
      @is_list = true if index.length == 1
      yield (self) if block_given?
    end

    def to_s
      "\n" + @ref.to_s + ':' + @name + "\n" + @index.to_s + "\n" + @rows.map {|row_ref, row|  row.to_s + "\n" }.join("")
    end

    def row(ref, name, unit = nil, vals = nil, &block)
      raise "Row must be defined with either values or a formula." if (vals.nil? and !block_given?)
      raise "Cant add another row with ref: " + ref.to_s if @rows.has_key?(ref) 
      unless @index.length==1 or vals.nil?
        raise "Values must be supplied for all rows (#{@index.length})." if vals.length != @index.length
      end
      row = Row.new(ref, name, unit, self, vals, block)
      @rows[row.ref] = row
      @model.rows[row.ref] = row
    end

    def [](row_ref)
      raise "Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'." unless @rows.has_key?(row_ref)
      @is_list ? @rows[row_ref].cells[0] : @rows[row_ref]
    end

    def []=(row_ref, new_values)
      raise "Row '#{row_ref.to_s}' not found in table '#{@ref.to_s}'." unless @rows.has_key?(row_ref)
      @rows[row_ref].values=new_values
    end
    
  end
end
