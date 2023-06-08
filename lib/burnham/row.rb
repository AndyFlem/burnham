module Burnham  
  class Row
    include Enumerable

    attr_reader :table, :model
    attr_reader :ref, :name, :metadata
    attr_reader :dependents
    attr_reader :is_formula, :is_run, :is_cells, :is_index, :hidden

    def new_row(ref, name, metadata, table, is_index, not_index_dependent, hidden, formula)      
      setup(ref, name, metadata, hidden, table)

      @is_cells = false
      @formula = formula
      @is_formula = true
      @is_run =  false
      @is_index = is_index
      @not_index_dependent = not_index_dependent
    end

    def new_cells(ref, name, metadata, table, is_index, hidden, vals, formula)
      #p ref.to_s + " " + is_index.to_s
      setup(ref, name, metadata, hidden, table)
    
      @is_cells = true
      @formula = formula
      @is_formula = (not formula.nil?)
      @is_run =  (not @is_formula)
      @is_index = is_index
      @is_index_dependent = true
      
      unless vals.nil?
        if vals.class == Array
          @cells = vals
        else
          @cells = [vals]
        end
      end
    end

    def setup(ref, name, metadata, hidden, table)
      @ref = ref
      @name = name
      @metadata = metadata
      @table = table
      @hidden = hidden
      @model = @table.model
      @dependents = Hash.new
    end

    def length
      @cells.nil? ? 0 : @cells.length
    end
    alias :width :length

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
        #puts "Set dirty " + address
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
        unless @is_index or @not_index_dependent
          #puts "Registering as dependent on index: " + address
          @table.index.register_dependent(self)
        end

        if @is_cells
          @cells = @table.index.cells.map.with_index do |c, i| 
            @formula.call(CellContext.new(self, i))
          end
        else
          @cells = @formula.call(Context.new(self))
        end
        @is_run = true
        raise RuntimeError.new("Row length (#{@cells.length}) does not equal table index length (#{@table.width}). " + address) if @cells.length != @table.width
        #puts "..complete run " + address + "."
      end
    end

    def [] (column_ref)      
      raise RuntimeError.new("Row not run." + address) unless @is_run
      indx = @table.index_of(column_ref)
      raise RuntimeError.new("Column #{column_ref.to_s} not found in table #{@table.ref.to_s}.") if indx.nil?
      @cells[indx]
    end

    def cells
      raise RuntimeError.new("Row not run " + address) unless @is_run
      @cells
    end

    def index_of(value) 
      raise RuntimeError.new("Row not run " + address) unless @is_run
      @cells.find_index(value)
    end

    def column (column_number)
      raise RuntimeError.new("Row not run.") unless @is_run
      raise ArgumentError.new("No column number #{column_number}") if column_number > @cells.length
      @cells[column_number]
    end

    def each(&block)
      @cells.each(&block)
    end
    
    def to_a
      @cells
    end

    def to_s
      max_cols = 4
      disp = []
      ret =  @name[...29].rjust(30) + ' - '
      unless @cells.nil?
        disp = if @cells.count > max_cols * 2
          @cells[...max_cols] + ['...'] + @cells[-max_cols...]
        else
          @cells
        end
        ret += disp.map do |e| 
          st = if e.class == Float
            sprintf('%.3f', e)
          else
            e.to_s
          end[0..9]
          st.rjust(10)
        end.join(', ')
      end
       
      ret 
    end

    def address
      "'#{name}' #{@table.ref.to_s}:#{ref.to_s} #{ @is_index ? 'index':'' } type: #{ @is_formula ? 'formula':'value' } state:#{ @is_run ? 'run':'not run' }"
    end

    def inspect
      address
    end

  end
end