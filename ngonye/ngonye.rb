require_relative '../lib/burnham'
require_relative '../../pulo/lib/pulo'

module Burnham
include Pulo
  main = Model.new 'Main' do |model|
    model.table :summary, 'Summary' do |table|
      table.row :some_val_av, 'Av of Some Val' do |c|
        c.row(table: :dates, row: :some_val).mean + c.row(table: :timing, row: :double_sum).mean
      end
    end    
    model.table :parameters, 'Timing Parameters' do |table|
      table.row :cod_date, 'Date of COD' do |c|
        c[:fc_date] >> c[:construction_months] 
      end
      table.row :periods, 'Model Months' do |c|
        c[:construction_months] + (c[:ppa_years] * 12) 
      end      
      table.row :fc_date, 'Date of Financial Close', Date.new(2023,10,1)
      table.row :construction_months, 'Construction Period', 36
      table.row :ppa_years, 'PPA Term', 25
    end
    model.table :cost_parameters, 'Costs' do |table|
      table.row :epc_cost, 'EPC Contract Cost', 400000
      
      table.row :contingency_pct, 'Owners Contingency Percent', 10.0
      table.row :contingency, 'Owners Contingency'  do |c|  
        c[:epc_cost] * (c[:contingency_pct] / 100)
      end
      
      table.row :es_cost, 'E&S Costs', 15000
      
      table.row :insurance_pct, 'Insurance Percent', 1.0
      table.row :insurance, 'Insurance' do |c|  
        c[:epc_cost] * (c[:insurance_pct] / 100)
      end
      
      table.row :owners_engineer_pct, 'Owners Engineer Percent', 2.0
      table.row :owners_engineer, 'Owners Engineer'  do |c| 
        c[:epc_cost] * (c[:owners_engineer_pct] / 100)
      end

      table.row :construction_cost, 'Construction Cost' do |c|
        c[:epc_cost] + 
        c[:contingency] +
        c[:es_cost] + 
        c[:insurance] +
        c[:owners_engineer]
      end
    end
    model.table :timing, 'Timing', (1..400) do |table|
      table.row :in_model, 'In Model' do |c|
        c.column_ref <= c[table: :parameters, row: :periods]
      end
      table.row :double_sum, 'Double Sum' do |c|
        (c[:sum] * 2) + c[table: :cost_parameters, row: :construction_cost] if c[:in_model]
      end      
      table.row :sum, 'Sum' do |c|
        c.row(:random).take(c.column_number).reduce(:+)
      end
      table.row :random, 'Random' do 
        1
      end      
    end
    model.table :months, 'Months', [1,2,3,4,5,6,7] do |table|
      table.row :month, 'Month', ['Jan','Feb','Mar','Apr','May','Jun','Jul']
      table.row :month_no, 'Month Number' do |c|
        c.column_number
      end
      table.row :some_val, 'Some Val', [3,6,23,7,3,6,8]
    end
    model.table :dates, 'Dates', (Date.new(2021,1,1) .. Date.new(2021,5,1)).to_a do |table|
      table.row :month_no, 'Month Number' do |c|
        c.column_ref.month
      end
      table.row :some_val, 'Some Val Lookup' do |c|
        c.lookup(return_row: :some_val, lookup: c[:month_no], lookup_row: :month_no, table: :months)
      end
    end
  end

  main.run
  puts main[:parameters][:periods]
  #puts main[:cost_parameters][:construction_cost]
  #puts main[:timing]
  #p main[:cost_parameters].rows[:construction_cost].dependents.keys
  #puts main[:months]
  #puts main[:dates]
  puts main[:summary]

  main[:parameters][:construction_months]=10
  main[:cost_parameters][:epc_cost] = 0

  main.run

  puts main[:parameters][:periods]
  puts main[:summary]
  #p main[:timing][:double_sum].to_a
  #puts Densities.ABS
end