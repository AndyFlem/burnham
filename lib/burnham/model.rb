module Burnham
  class Model
    attr_reader :tables, :rows, :name

    def initialize(name, &block)
      @name=name
      @tables = Hash.new
      @rows = Hash.new
      yield (self) if block_given?
    end

    def table(ref, name, &block)
      raise ArgumentError.new("Cant add another table with the same ref.") if @tables.has_key?(ref)
      #columns = columns.to_a if columns.class == Range
      table = Table.new(ref, name, self, &block)
      @tables[table.ref] = table
      table
    end

    def register_row(row)
      @rows[[row.table.ref, row.ref]] = row
    end

    def [](table_ref)
      raise ArgumentError.new("Table '#{table_ref.to_s}' not found in model '#{@name}'.") unless @tables.has_key?(table_ref)
      @tables[table_ref]
    end

    def run
      @tables.each_value do |table|
        if table.index.nil?
          table.cells :index, 'Index', [:value]
        end
      end
      @rows.each_value(&:run)      
    end

  end  
end