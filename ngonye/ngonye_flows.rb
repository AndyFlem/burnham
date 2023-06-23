require_relative '../lib/burnham'
require 'date'
require_relative '../../pulo/lib/pulo'
require 'benchmark'

module Burnham

  csv_converter = proc do |value, field_info|
    case field_info.header
    when 'Date'
      Date.strptime(value,'%d/%m/%Y')
    when 'Flow'
      value.to_f
    when 'Level'
      value.to_f
    end
  rescue
    puts field_info.header + ':' + value
  end  

  flows_model = Model.new('Ngonye Flows Model')

  flows_model.table :params, 'Parameters' do |t|
    #Ngonye Discharge = 1093.0355*(Ngonye Stage - 2.85)**1.659
    #Ngonye Discharge = a *(Ngonye Stage + b)**c
    t.cells :ngo_a, 'Ngonye Stage Discharge Param a', 1093.0355 
    t.cells :ngo_b, 'Ngonye Stage Discharge Param b', -2.85
    t.cells :ngo_c, 'Ngonye Stage Discharge Param c', 1.659 
    t.cells :fdc_interval, 'FDC Interval Percent', 0.1 
    t.cells :lag, 'Vic Falls to Sioma Lag Days', 11 
  end

  flows_model.table_from_csv :flow_vicfalls, 'Vic Falls Flows', './ngonye/daily_gauge_vicfalls_2022.csv', csv_converter

  flows_model.table_from_csv :flow_ngonye, 'Ngonye Flows', './ngonye/daily_gauge_ngonye_2022.csv', csv_converter do |t|
    t.cells :flow_ngonye, 'Flow at Ngonye' do |c|
      #Ngonye Discharge = a *(Ngonye Stage + b)**c
      (c[table: :params, row: :ngo_a] * (c[:level] + c[table: :params, row: :ngo_b])**c[table: :params, row: :ngo_c])
    end
  end

  flows_model.table_join(:flows_all, 'All Vic Falls and Ngonye Flows', :flow_vicfalls, :date, :flow_ngonye, :date, [:date, :flow=>:flow_vicfalls], [:flow_ngonye], true)

  flows_model[:flows_all][:flow_vicfalls].name = 'Flow at Vic Falls'
  flows_model.table_select :flow, 'Flows', :flows_all, :date, proc {|v|  v<=Date.new(2020,9,30)}

  # split = proc {|vals, intervals|
  #   interval = vals.length.to_f / intervals
  #   (0..intervals).to_a.map do |v| 
  #     i = v * interval
  #     d = i-i.floor
  #     i -=1 if i == vals.length
  #     if d==0
  #       vals[i]
  #     else
  #       vals[i] - (vals[i]-vals[i+1])*d
  #     end
  #   end
  # }

  # flows_model.table :fdc, 'Flow Duration Curve' do |t|
  #   t.row :exceedance, 'Exceedance' do |c| 
  #     (1..100/c[table: :params, row: :fdc_interval]+1).to_a.map do 
  #       |v| (c[table: :params, row: :fdc_interval] * (v-1)/100).round(3)
  #     end
  #   end

  #   t.row :flow_ngonye, 'Ngonye Flow' do |c|
  #     vals = c[table: :flow, row: :flow_ngonye].to_a.sort_by {|v| 10000-v }
  #     intervals = 100/c[table: :params, row: :fdc_interval]
  #     split.call vals, intervals
  #   end
 
  #   t.row :flow_vicfalls, 'Vic Falls Flow' do |c|
  #     vals = c[table: :flow_vicfalls, row: :flow].to_a.sort_by {|v| -v }
  #     intervals = 100/c[table: :params, row: :fdc_interval]
  #     split.call vals, intervals
  #   end
    
  #   t.row :flow_vicfalls_overlap, 'Vic Falls Overlap Flow' do |c|
  #     vals = c[table: :flow, row: :flow_vicfalls].to_a.sort_by {|v| -v }
  #     intervals = 100/c[table: :params, row: :fdc_interval]
  #     split.call vals, intervals
  #   end    

  #   t.cells :flow_vicfalls_ratio, 'Vic Falls Flow Ratio' do |c|
  #     c[:flow_vicfalls]/c[:flow_vicfalls_overlap]
  #   end

  #   t.row :flow_vicfalls_ratio_smooth, 'Vic Falls Ratio Smoothed' do |c|
  #     c[:flow_vicfalls_ratio].to_a.map.with_index do |v,i|
  #       if (i<10 or i>990)
  #         v
  #       else
  #         c[:flow_vicfalls_ratio].to_a[i-3..i+3].sum/7
  #       end
  #     end
  #   end
  #   t.cells :ngonye_scaled, 'Ngonye Scaled Flow' do |c|
  #     c[:flow_ngonye]*c[:flow_vicfalls_ratio_smooth]
  #   end

  #   t.cells :conversion, 'Conversion Factor' do |c|
  #     c[:ngonye_scaled]/c[:flow_vicfalls]
  #   end
  # end

  # flows_model.table_sort(:exceedance, 'Flows by Exceedance', :flow_vicfalls, :flow, proc {|v| - v}) do |t|
  #   t.row ref: :no, hidden: true do |c|
  #     (1..c[table: :flow_vicfalls].width).to_a
  #   end
  #   t.cells :lagged_date, 'Lagged Date' do |c|
  #     c[:date] - c[table: :params, row: :lag]
  #   end

  #   t.row :exceedance, 'Exceedance' do |c|
  #     r = c[:no].to_a
  #     tot = r.count
  #     c[:no].to_a.map { |v| (v.to_f/tot)}
  #   end

  #   t.row :conversion, 'Conversion Factor' do |c|
  #     lookup_point = -1
  #     lookup = c[table: :fdc, row: :exceedance].to_a 
  #     values = c[table: :fdc, row: :conversion].to_a
  #     cross = -1

  #     c[:exceedance].to_a.map do |ex|
  #       while ex > cross
  #         lookup_point += 1
  #         if lookup_point < lookup.length-1
  #           cross = (lookup[lookup_point+1] - lookup[lookup_point])/2 + lookup[lookup_point]
  #         else
  #           cross = 1000
  #         end
  #       end
  #       values[lookup_point]
  #     end
  #   end
  #   t.cells :flow_ngonye, 'Ngonye Synthetic Flow' do |c|
  #     c[:conversion] * c[:flow]
  #   end
  # end

  # flows_model.table_sort :synthetic, 'Ngonye Synthetic Flows', :exceedance, :date do |t|
  # end

  puts Benchmark.measure {flows_model.run}
  
  puts flows_model[:flows_all]
  puts flows_model[:flow]
  #puts flows_model[:fdc]
  #puts flows_model[:exceedance]
  #puts flows_model[:synthetic]

  #puts Benchmark.measure {flows_model.to_xlsx 'flows.xlsx', [:params, :fdc, :synthetic]}
end
