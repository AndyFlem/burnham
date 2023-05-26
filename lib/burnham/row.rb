module Burnham  
  class Row
    include Enumerable

    attr_reader :table, :model
    attr_reader :ref, :name, :metadata
    attr_reader :dependents 
    attr_reader :is_formula, :is_run

    def initialize(ref, name, metadata, parent_table, vals, block)
      @ref = ref
      @name = name
      @metadata = metadata
      @table = parent_table
      @model = @table.model
      @is_formula = vals.nil?
      @formula = block
      @is_run = !@is_formula

      @dependents = Hash.new

      if @is_formula
        @contexts = @table.columns.to_a.map do |columns|
          Context.new(self, columns[0], columns[1]+1)
        end  
      else
        @cells = @table.columns.to_a.map do |columns|
          vals.class == Array ? vals[columns[1]] : vals
        end        
      end
    end

    def values=(vals)
      raise RuntimeError.new("Cant set values on a formula type row.") if @is_formula
      if @cells.length == 1
        @cells[0] = vals
      else
        @cells = vals
      end
      set_dirty
    end

    def set_dirty
      if @is_run
        puts "Set dirty " + address
        if @is_formula
          @is_run = false
          @cells = nil
        end
        @dependents.each_value(&:set_dirty)
      end
    end

    def register_dependent(row)
      run unless @is_run
      unless @dependents.has_key?([row.table.ref, row.ref])
        # puts "Registering dependent " + row.address + " on " + address
        @dependents[[row.table.ref, row.ref]] = row 
      end
    end
    
    def run
      if @is_formula and not @is_run
        #puts "Running " + address + ".."
        @cells = @contexts.map do |context| 
          @formula.call(context)
        end
        @is_run = true
        #puts "..complete run " + address + "."
      end  
    end

    def [] (column_ref)
      raise ArgumentError.new("Column '#{column_ref.to_s}' not found in row '#{@ref.to_s}' of table '#{@table.ref.to_s}'.") unless @table.columns.include?(column_ref)
      raise RuntimeError.new("Row not run." + address) unless @is_run
      @cells[@table.columns[column_ref]] #.value
    end

    def cells
      raise RuntimeError.new("Row not run " + address) unless @is_run
      @cells
    end

    def column (column_number)
      raise ArgumentError.new("No column number #{column_number}") if column_number > @cells.length
      raise RuntimeError.new("Row not run.") unless @is_run
      @cells[column_number]
    end

    def each(&block)
      @cells.each(&block)
    end
    
    def to_a
      @cells
    end

    def to_s
      @ref.to_s + ':' + @name  +  ' ' + (@cells.nil? ? 'nil' : @cells.join(','))
    end

    def address
      "'#{name}' #{@table.ref.to_s}:#{ref.to_s} type: #{ @is_formula ? 'formula':'value' } state:#{ @is_run ? 'run':'not run' }"
    end

    def inspect
      address
    end

  end
end