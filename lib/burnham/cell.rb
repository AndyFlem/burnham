module Burnham
  class Cell
    attr_reader :column_ref, :column_number, :is_formula, :is_run
    attr_reader :row, :table, :model

    def initialize(row, column_ref, column_number, value, block)
      raise "Cell can only be defined with values or a formula." if not (value.nil? or block.nil?)
      raise "Cell must be defined with either value or a formula." if (value.nil? and block.nil?)
      
      @row = row
      @table = row.table
      @model = @table.model
      @column_ref = column_ref
      @column_number = column_number
      
      @is_formula = value.nil?
      @is_run = !@is_formula

      if @is_formula
        @formula = block
      else
        @value = value
      end
      @context = Context.new(self)
    end

    def value=(new_value)
      raise "Cant set a value on a formula type row cell."  + address if @is_formula
      @value = new_value
    end
    
    def run
      raise "Can only run a formula type row cell." + address unless @is_formula
      unless @is_run
        @value = @formula.call(@context)
        @is_run = true
      end
    end

    def == (other)
      value == (other.class == Cell ? other.value : other)
    end

    def value
      run unless @is_run || !@is_formula
      @value
    end

    def address
      "[#{@row.table.ref.to_s} #{@row.table.is_list ? '(list)' : ''}, #{@row.ref.to_s} (#{@row.is_formula ? 'row formula': ''}), #{@column_ref}]"
    end

    def to_s
      @value.to_s
    end

    def method_missing(method, *args)
      #puts method
      value.send(method, *args)   
    end
  end
end
