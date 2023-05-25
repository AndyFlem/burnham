module Burnham
  class Model
    attr_reader :tables, :rows, :name

    def initialize(name, &block)
      @name=name
      @tables = Hash.new
      @rows = Hash.new
      yield (self) if block_given?
    end

    def table(ref, name, index = [:value], &block)
      index = index.to_a if index.class == Range
      table = Table.new(ref, name, self, index, &block)
      @tables[table.ref] = table
      table
    end

    def [](table_ref)
      raise "Table '#{table_ref.to_s}' not found in model '#{@name}'." unless @tables.has_key?(table_ref)
      @tables[table_ref]
    end

    def run
      @rows.each_value(&:run)      
    end

  end  
end