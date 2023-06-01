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
        list.cells :date, 'Date of Financial Close', Date.new(2023,10,1)
        list.cells :construction_months, 'Construction Period', 5.0
      end
    end
    it 'allows the creation of a list type table with values and calculations' do
      @model.table :list2, 'List2' do |list|
        list.cells :multiply, 'Multiply'  do |c|
          c[:construction_months] * c[:ppa_years]
        end
        list.cells :construction_months, 'Construction Period', 36
        list.cells :ppa_years, 'PPA Term', 5
      end

    end    
    it 'should raise an argument error for a duplicate table ref' do
      expect { @model.table :list, 'List' }.to raise_error(ArgumentError)
    end
    it 'should raise an argument error for a duplicate row ref' do
      expect do 
        @model.table :new_list, 'List' do |list|
          list.cells :item, 'Item', 25
          list.cells :item, 'Item2', 25
        end
      end.to raise_error(ArgumentError)
    end
    it 'should allow creation of table type tables and various row styles' do
      @model.table :table1, 'Table1' do |table|
        table.cells :row1, 'Row 1', ['Col1', 'Col2', 'Col3', 'Col4']
        table.cells ref: :row2, name: 'Row 2', metadata: {desc: 'A description for row 2'}, values: [1,2,3,4]
        table.cells ref: :row3, name: 'Row 3', metadata: {desc: 'A description for row 3'} do |c|
          c[:row2] * 2
        end
      end
       
      expect(@model[:table1].height).to eq 3
      expect(@model[:table1].width).to eq 4
      expect(@model[:table1][:row2].metadata[:desc]).to eq 'A description for row 2'
      expect {@model[:table1][:row3]['Col3']}.to raise_error(RuntimeError)
    end
    it 'should allow cells formula with cell references' do
      @model.table :table2, 'Table2' do |t|
        t.cells :index, 'Index', ['Col1', 'Col2', 'Col3', 'Col4']
        t.cells :row_a, 'Row A' do |c|
          c[table: :list, row: :construction_months] + c.column_number
        end
        t.cells :row_b, 'Row B' do |c|
          #Same column of another row in same table
          c[:row_a] + 5
        end
        t.cells :row_c, 'Row C' do |c|
          #Same column no of row in another table
          c[table: :table1, row: :row2] + 1
        end
        t.cells :row_d, 'Row D' do |c|
          #Table, row and column
          c[table: :table1, row: :row2, column: 'Col3'] + 1
        end
        t.cells :row_e, 'Row E' do |c|
          #row and column offset
          c[row: :row_a, column_offset: -2]
        end              
      end
    end
    it 'should allow cells formula with cell lookups' do
      @model.table :months, 'Months' do |t|
        t.cells :month_name, 'Month', ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        t.cells :month_no, 'Month No' do |c| c.column_number + 1 end
        t.cells :val1, 'Val 1', [10,20,30,40,10,20,30,40,10,20,30,40]
        t.cells :val2, 'Val 2', ['J','F','M','A','M','J','J','A','S','O','N','D']
      end
      @model.table :table3, 'Lookups' do |t|
        t.cells :no, 'Number', (1..200)
        t.cells :date, 'Date' do |c|
          c[table: :list, row: :date] + c.column_number
        end
        t.cells :month_no, 'Month Number' do |c|
          c[:date].month
        end
        t.cells :month, 'Month' do |c|
          c.lookup(lookup: c[:month_no], table: :months, return_row: :month_name, lookup_row: :month_no)
        end
        t.cells :letter, 'Month Letter' do |c|
          c.lookup(lookup: c[:month], table: :months, return_row: :val2)
        end
        t.cells :val, 'Some Val' do |c|
          c.lookup(lookup: c[:letter], table: :months, lookup_row: :val2 ,return_row: :val1)
        end        
      end
    end

    it 'should allow table defined with a row formula' do
      @model.table :groups, 'Groups' do |t|
        t.row :month, 'Month' do |c|
          c[table: :table3, row: :month_no].to_a.uniq
        end
        t.cells :days, 'Days' do |c|
          c.row(table: :table3, row: :date).filter {|a| a.month == c[:month]}.length
        end
        t.row :days2, 'Days2' do |c|
          c[table: :table3, row: :date].group_by {|a| a.month }.map {|a| a[1].length}
        end        
      end
    end
    it 'should allow the model to be run' do
      @model.run
      
      #puts @model[:groups]
      expect(@model[:list2][:multiply]).to eq 180
      expect {@model[:table1][:row3]['Col21']}.to raise_error(RuntimeError)       
      expect(@model[:table1][:row3]['Col2']).to eq 4
      expect(@model[:table2][:row_a]['Col1']).to eq 5
      expect(@model[:table2][:row_b].to_a[1]).to eq 11
      expect(@model[:table2][:row_c].to_a).to eq [2, 3, 4, 5]
      expect(@model[:table2][:row_d].to_a[1]).to eq 3        
      expect(@model[:table3][:letter][10]).to eq 'O'
      expect(@model[:table3][:month][5]).to eq 'Oct'
      #expect(@model[:table3][:row_e]['ColA']).to eq nil
      
    end
    it 'should allow the model to be modified and rerun' do
      @model[:list][:date] = Date.new(2022,1,1) 
      @model.run
      #puts @model[:groups]

      expect(@model[:table3][:letter][10]).to eq 'J'
      expect(@model[:table3][:month][5]).to eq 'Jan'
      expect(@model[:groups][:days2][2]).to eq 28
    end
    it 'should allow you to load from csv' do
      custom_converter = proc do |value, field_info|
        case field_info.header
        when 'Date'
          Date.strptime(value,'%d/%m/%Y')
        when 'Flow'
          value.to_f
        end
      rescue
        puts field_info.header + ':' + value
      end
      model2 = Model.new('CSV Model')

      model2.table :params, 'Params' do |list|
        list.cells :multiplier, 'Multiplier', 2
      end

      model2.table_from_csv :flows, 'Flows', './spec/flows.csv', custom_converter do |table|
        table.cells :double, 'Double' do |c| c[:flow] * c[table: :params, row: :multiplier] end
      end

      model2.table_of_aggregates :flows, :flows_monthly, 'MOnthly Flows', :month,'MOnth',:date, proc {|date| Date.new(date.year, date.month) } , {flow: [:count, :mean, :median], double: [:count, :mean]} do |t|
          t.cells :max_of_means, 'Max of Means' do |c|
            [c[:flow_mean], c[:double_mean]].max
          end 
      end
  
      model2.run
      expect(model2[:flows][:flow][Date.new(1925,02,11)]).to eq 1183.4396
      expect(model2[:flows][:double][Date.new(1925,02,11)]).to eq 1183.4396*2

      expect(model2[:flows_monthly][:max_of_means][Date.new(1924,10,01)]).to eq 200.0
      
      model2[:params][:multiplier] = 3
      model2.run

      expect(model2[:flows_monthly][:max_of_means][Date.new(1924,10,01)]).to eq 300.0
      
      #puts model2[:flows_monthly][:month]

      #p model2[:flows].columns
      #p model2[:flows][:flow]
      
    end
  end
end