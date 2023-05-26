require_relative '../lib/burnham'
require 'date'
#require_relative '../../pulo/lib/pulo'


module Burnham
  RSpec.describe Model do
    it "allows the creation of a new model" do
      model = Model.new('Test Model')
      expect(model.name).to eq('Test Model')
    end
  end

  RSpec.describe Model do
    before(:all) do 
      @model = Model.new('Test Model')
    end
    it 'allows the creation of a new list type table with values' do
      @model.table :list, 'List' do |list|
        list.row :date, 'Date of Financial Close', Date.new(2023,10,1)
        list.row :construction_months, 'Construction Period', 1.0
      end
      expect(@model[:list][:date]).to eq Date.new(2023,10,1)
    end
    it 'allows the creation of a list type table with values and calculations' do
      @model.table :list2, 'List2' do |list|
        list.row :multiply, 'Multiply'  do |c|
          c[:construction_months] * c[:ppa_years]
        end
        list.row :construction_months, 'Construction Period', 36
        list.row :ppa_years, 'PPA Term', 25
      end

    end    
    it 'should raise an argument error for a duplicate table ref' do
      expect { @model.table :list, 'List' }.to raise_error(ArgumentError)
    end
    it 'should raise an argument error for a duplicate row ref' do
      expect do 
        @model.table :new_list, 'List' do |list|
          list.row :item, 'Item', 25
          list.row :item, 'Item2', 25
        end
      end.to raise_error(ArgumentError)
    end
    it 'should allow creation of table type tables and various row styles' do
      @model.table :table1, 'Table1', ['Col1','Col2','Col3','Col4'] do |table|
        table.row :row1, 'Row 1', [1,2,3,4]
        table.row :row2, 'Row 2', {desc: 'A description for row 2'}, [1,2,3,4]
        table.row :row3, 'Row 3', {desc: 'A description for row 3'} do |c|
          c[:row2] * 2
        end
      end
       
      expect(@model[:table1].rows.length).to eq 3
      expect(@model[:table1].columns.length).to eq 4
      expect(@model[:table1][:row2].metadata[:desc]).to eq 'A description for row 2'
      expect {@model[:table1][:row3]['Col3']}.to raise_error(RuntimeError) 
    end
    it 'should allow row formula with cell references' do
      @model.table :table2, 'Table2', ['ColA','ColB','ColC','ColD'] do |t|
        t.row :row_a, 'Row A', [10, 20, 30, 40]
        t.row :row_b, 'Row B' do |c|
          #Same column of another row in same table
          c[:row_a] + 5
        end
        t.row :row_c, 'Row C' do |c|
          #Same column no of row in another table
          c[table: :table1, row: :row2] + 1
        end
        t.row :row_d, 'Row D' do |c|
          #Table, row and column
          c[table: :table1, row: :row2, column: 'Col3'] + 1
        end
        t.row :row_e, 'Row E' do |c|
          #row and column offset
          c[row: :row_a, column_offset: -2]
        end              
      end
    end
    it 'should allow row formula with cell lookups' do
      @model.table :months, 'Months', ['Jan','Feb','Mar','Apr'] do |t|
        t.row :month, 'Month' do |c| c.column_number end
        t.row :val1, 'Val 1', [10,20,30,40]
        t.row :val2, 'Val 2', ['J','F','M','A']
      end
      @model.table :table3, 'Lookups', (1..20) do |t|
        t.row :date, 'Date' do |c|
          c[table: :list, row: :date] + c.column_number
        end
        t.row :month, 'Month' do |c|
          ['Jan','Feb','Mar','Apr'][(rand*3).round]
        end
        t.row :letter, 'Month Letter' do |c|
          c.lookup(lookup: c[:month], table: :months, return_row: :val2)
        end
        t.row :val, 'Some Val' do |c|
          c.lookup(lookup: c[:letter], table: :months, lookup_row: :val2 ,return_row: :val1)
        end        
      end
    end
    it 'should allow row formula with row ranges' do
      @model.table :data, 'Data', (1..200) do |t|
        t.row :date, 'Date' do |c|
          c[table: :list, row: :date] + c.column_number
        end
        t.row :month, 'Month' do |c|
          c[:date].month
        end
        t.row :val, 'Value' do |c|
          (rand * 100).round
        end
      end

      @model.table :months, 'Summary' do |t|

      end

      @model.table :summary, 'Summary' do |t|
        #t.row :sum, 'Sum' do |c|
          #c.range(table: :table3, row: )
        #end
      end
    end
    it 'should allow the model to be run' do
      @model.run
      puts @model[:table3]
      puts @model[:list]
      expect(@model[:table1][:row3]['Col2']).to eq 4
      expect(@model[:table2][:row_b].to_a[1]).to eq 25
      expect(@model[:table2][:row_c].to_a).to eq [2, 3, 4, 5]
      expect(@model[:table2][:row_d]['ColA']).to eq 3
      expect(@model[:table2][:row_e]['ColA']).to eq nil
      expect(@model[:table2][:row_e]['ColD']).to eq 20
      
    end
  end
end