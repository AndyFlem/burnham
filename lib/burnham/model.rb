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

    def table_from_csv(ref, name, file_name, converters, &block)
      data = CSV.parse(File.read(file_name), headers: true, converters: converters)
      
      table = table ref, name do |t|
        data.by_col.each.with_index do |col, indx|
          t.cells data.headers[indx].gsub(' ','').downcase.to_sym, data.headers[indx], col[1]
        end
      end
      yield table
      table
    end

    def table_of_aggregates(
      input_table_ref, 
      output_table_ref, 
      output_table_name, 
      output_group_ref,
      output_group_name,
      group_row, 
      group_fn, 
      aggregates, 
      &block)

      #input_table = @tables[input_table_ref]
      
      output_table = table output_table_ref, output_table_name do |t|      
        t.row(ref: :groups, name: 'Groups', not_index: true, not_index_dependent: true) do |c|
          #produces groups of column numbers of the parent table based on the provided grouping function
          rw = c[table: input_table_ref, row: group_row].to_a
          rw.map{|o| group_fn.call(o)}.zip((0..rw.count-1).to_a).group_by{ |o| o[0] }.map{|o| [o[0],  o[1].map{|p| p[1]}]}
        end
        t.row output_group_ref, output_group_name do |c|
          c[:groups].map {|o| o[0]}
        end        
        aggregates.each_pair do |row, operators|
          #produce a row with groups of values of the input row
          val_groups = (row.to_s + '_values').to_sym
          t.cells val_groups, val_groups.to_s do |c|
            c[:groups][1].map { |indx| c[table: input_table_ref, row: row, column_number: indx] }
          end
          operators.each do |operator|
            t.cells (row.to_s + '_' + operator.to_s).to_sym, row.to_s + '_' + operator.to_s do |c|
              c[val_groups].send(operator)
            end
          end
        end
      end
      yield output_table
      output_table
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