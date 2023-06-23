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
      yield table if block_given?
      table
    end

    def table_sort(
      output_table_ref,
      output_table_name,
      input_table_ref,
      sort_row_ref,
      sort_fn = proc {|v| v},
      &block)

      output_table = table output_table_ref, output_table_name do |t|      
        t.row ref: :order_pairs, hidden: true, not_index: true, not_index_dependent: true do |c|
          c[table: input_table_ref, row: sort_row_ref].to_a.map {|v| sort_fn.call(v)}.zip(*@tables[input_table_ref].rows.values.map(&:to_a)).sort_by {|v| v[0]}
        end
        @tables[input_table_ref].rows.each_value.with_index do |rw,i|
          unless rw.hidden
            t.row ref: rw.ref, name: rw.name do |c|
              c[:order_pairs].map { |v| v[i+1] }
            end
          end
        end
      end
      yield output_table if block_given?
      output_table
    end

    def table_of_aggregates(
      output_table_ref, 
      output_table_name, 
      input_table_ref, 
      output_group_ref,
      output_group_name,
      group_row, 
      group_fn, 
      aggregates, 
      &block)

      output_table = table output_table_ref, output_table_name do |t|      
        t.row output_group_ref, output_group_name do |c|
          c[:groups].map {|o| o[0]}
        end        
        t.row(ref: :groups, hidden: true, not_index: true, not_index_dependent: true) do |c|
          #produces groups of column numbers of the parent table based on the provided grouping function
          rw = c[table: input_table_ref, row: group_row].to_a
          rw.map{|o| group_fn.call(o)}.zip((0..rw.count-1).to_a).group_by{ |o| o[0] }.map{|o| [o[0],  o[1].map{|p| p[1]}]}
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
      yield output_table if block_given?
      output_table
    end

    def table_join(
      output_table_ref, 
      output_table_name, 
      left_table_ref, 
      left_row_ref, 
      right_table_ref, 
      right_row_ref, 
      left_rows, 
      right_rows, 
      is_outer)
      
      left_table = @tables[left_table_ref]
      right_table = @tables[right_table_ref]

      output_table = table output_table_ref, output_table_name do |t|  
        indexes = []
        right_pointer = 0
        t.row ref: :indexes, hidden: true do |c|
          right = c[table: right_table_ref, row: right_row_ref].to_a 
          c[table: left_table_ref, row: left_row_ref].to_a.each.with_index do |lval, left_pointer|
            if lval == right[right_pointer]
              indexes << [ left_pointer, right_pointer ]
              right_pointer +=1
              break if right_pointer == right.length
            else
              indexes << [ left_pointer, nil ] if is_outer
            end
          end
          indexes
        end

        rows_build = proc  do |rows, table, is_left|
          rows.each do |row_def|
            if row_def.class == Hash
              in_row_ref = row_def.keys[0]
              out_row_ref = row_def.values[0]
            else
              in_row_ref = row_def
              out_row_ref = row_def
            end
            
            t.row out_row_ref, table.rows[in_row_ref].name do |c|
              rw = c[table: table.ref, row: in_row_ref].to_a
              c[:indexes].map do |v|

                if is_left 
                  rw[v[0]]
                else
                  rw[v[1]] if v[1]
                end
              end
            end
          end
        end

        rows_build.call(left_rows, left_table, true)
        rows_build.call(right_rows, right_table, false)
        
      end
      yield output_table if block_given?
      output_table
    end

    def table_select(
      output_table_ref, 
      output_table_name, 
      input_table_ref, 
      select_row, 
      select_fn, 
      output_rows = [])

      output_table = table output_table_ref, output_table_name do |t|      

        #row of selected column numbers from the parent table
        t.row(ref: :column_nos, hidden: true, not_index: true, not_index_dependent: true) do |c|
          rw = c[table: input_table_ref, row: select_row].to_a
          rw.map{|v| select_fn.call(v) }.zip((0..rw.length).to_a).select{|v| v[0]}.map{|v| v[1]}
        end

        #selected columns of rows from input table
        @tables[input_table_ref].rows.each_value do |rw|
          unless rw.hidden or (output_rows != [] and not output_rows.include?(rw.ref))
            t.row ref: rw.ref, name: rw.name do |c|
              dat = c[table: input_table_ref, row: rw.ref].to_a
              c[:column_nos].map { |v| dat[v] }
            end
          end
        end
      end
      yield output_table if block_given?
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

    def to_xlsx(name, tables)
      Axlsx::Package.new do |p|

        row_title = p.workbook.styles.add_style(sz: 9, b: true)

        float_format = lambda do |val| 
          begin
            scale = [(val != 0.0 ? Math.log10(val.abs).floor : -1), -5].max
            p.workbook.styles.add_style(sz: 9, format_code: '#,##0' + (scale<3 ? ('.000' + '#' * (scale-2).abs) : ''))  
          rescue => e
            p val, e
          end
        end

        format_value = lambda do |val|
          case val
          when Float
            float_format.call(val)
          when Integer
            p.workbook.styles.add_style(sz: 9, format_code: '#,##0')
          when Date
            p.workbook.styles.add_style(sz: 9, format_code: 'yyyy-mm-dd')
          else
            nil
          end
        end

        @tables.each_value do |t|
          if tables.include? t.ref
            p.workbook.add_worksheet(name: t.name) do |sheet|
              heads = t.rows.values.select {|r| not r.hidden}.map {|r| r.name}
              styles = t.rows.values.select {|r| not r.hidden}.map {|r| format_value.call(r.to_a[(r.width/2.floor)])}
              sheet.add_row(heads, style: (1..heads.length).map {row_title}, widths: (1..heads.length).map {:ignore}, height: 40)
              dat = t.columns 
              dat.each do |r|
                sheet.add_row(r, style: styles)
              end
            end
          end
        end
        p.serialize(name)
      end
    end
  end
end