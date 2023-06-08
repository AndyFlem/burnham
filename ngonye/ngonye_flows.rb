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
      value.to_f.round(1)
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
    t.cells :ngo_b, 'Ngonye Stage Discharge Param b', - 2.85 
    t.cells :ngo_c, 'Ngonye Stage Discharge Param c', 1.659 
    t.cells :fdc_interval, 'FDC Interval Percent', 0.1 
    t.cells :lag, 'Vic Falls to Sioma Lag Days', 11 
  end

  flows_model.table_from_csv :flow_vicfalls, 'Vic Falls Flows', './ngonye/daily_gauge_vicfalls.csv', csv_converter do |t|

  end

  flows_model.table_from_csv :flow, 'Ngonye Measured Levels', './ngonye/daily_gauge_ngonye.csv', csv_converter do |t|
    t.cells :flow_ngonye, 'Flow at Ngonye' do |c|
      #Ngonye Discharge = a *(Ngonye Stage + b)**c
      (c[table: :params, row: :ngo_a] * (c[:level] + c[table: :params, row: :ngo_b])**c[table: :params, row: :ngo_c]).round(1)
    end
    t.row :flow_vicfalls, 'Flow at Vic Falls' do |c|
      c.filter :flow_vicfalls, :date, :flow do |date|
        date >= c[:date].to_a.first and date <= c[:date].to_a.last 
      end
    end
  end

  flows_model.table :fdc, 'Flow Duration Curve' do |t|
    t.row :exceedance, 'Exceedance' do |c| 
      (1..100/c[table: :params, row: :fdc_interval]+1).to_a.map do 
        |v| (c[table: :params, row: :fdc_interval] * (v-1)).round(3)
      end
    end

    t.row :flow_ngonye, 'Ngonye Flow' do |c|
      vals = c[table: :flow, row: :flow_ngonye].to_a.sort
      intervals = 100/c[table: :params, row: :fdc_interval]
      interval = vals.length / intervals
      (0..intervals).to_a.map do |v| 
        i = (vals.length-(v * interval).round)
        i -=1 if i == vals.length 
        vals[i]
      end
    end
 
    t.row :flow_vicfalls, 'Vic Falls Flow' do |c|
      vals = c[table: :flow_vicfalls, row: :flow].to_a.sort
      intervals = 100/c[table: :params, row: :fdc_interval]
      interval = vals.length / intervals
      (0..intervals).to_a.map do |v| 
        i = (vals.length-(v * interval).round)
        i -=1 if i == vals.length 
        vals[i]
      end
    end
    
    t.row :flow_vicfalls_overlap, 'Vic Falls Overlap Flow' do |c|
      vals = c[table: :flow, row: :flow_vicfalls].to_a.sort
      intervals = 100/c[table: :params, row: :fdc_interval]
      interval = vals.length / intervals
      (0..intervals).to_a.map do |v| 
        i = (vals.length-(v * interval).round)
        i -=1 if i == vals.length 
        vals[i]
      end
    end    

    t.cells :flow_vicfalls_ratio, 'Vic Falls Flow Ratio' do |c|
      c[:flow_vicfalls]/c[:flow_vicfalls_overlap]
    end

    t.row :flow_vicfalls_ratio_smooth, 'Vic Falls Ratio Smoothed' do |c|
      c[:flow_vicfalls_ratio].to_a.map.with_index do |v,i|
        if (i<10 or i>990)
          v
        else
          c[:flow_vicfalls_ratio].to_a[i-3..i+3].sum/7
        end
      end
    end
    t.cells :ngonye_scaled, 'Ngonye Scaled Flow' do |c|
      c[:flow_ngonye]*c[:flow_vicfalls_ratio_smooth]
    end

    t.cells :conversion, 'Conversion Factor' do |c|
      c[:ngonye_scaled]/c[:flow_vicfalls]
    end
  end


  flows_model.table_sort :flow_vicfalls, :flow, :exceedance, 'Flows by Exceedance' do |t|
    t.row ref: :no, hidden: true do |c|
      (1..c[table: :flow_vicfalls].width).to_a
    end
    t.row :exceedance, 'Exceedance' do |c|
      r = c[:no].to_a
      tot = r.count
      c[:no].to_a.map { |v| v.to_f/tot}
    end

    t.row :conversion, 'Conversion Factor' do |c|
      lookup_point = -1
      lookup = c[table: :fdc, row: :exceedance].to_a 
      values = c[table: :fdc, row: :conversion].to_a
      cross = -1

      c[:exceedance].to_a.map do |ex|
        while ex > cross
          lookup_point += 1
          if lookup_point < lookup.length-1
            cross = (lookup[lookup_point+1] - lookup[lookup_point])/2 + lookup[lookup_point]
          else
            cross = 1000
          end
        end
        values[lookup_point]
      end
    end
    t.cells :flow_ngonye, 'Ngonye Synthetic Flow' do |c|
      c[:conversion] * c[:flow]
    end
    t.cells :lagged_date, 'Lagged Date' do |c|
      c[:date] + c[table: :params, row: :lag]
    end
  end

  flows_model.table_sort :exceedance, :date, :synthetic, 'Ngonye Synthetic Flows' do |t|
  end

  puts Benchmark.measure {flows_model.run}
  #puts flows_model[:flow].column_to_s(0)
  #puts flows_model[:flows_vicfalls].width
  puts flows_model[:flow]
  puts flows_model[:fdc]
  #puts flows_model[:exceedance]
  #puts flows_model[:synthetic]
end