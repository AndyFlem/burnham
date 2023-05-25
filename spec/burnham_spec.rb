require_relative '../lib/burnham'
require 'date'

module Burnham
  RSpec.describe Model do
    it "allows the creation of a new model" do
      model = Model.new('Test Model')
      expect(model.name).to eq('Test Model')
    end
  end

  RSpec.describe Model do
    before(:all) do 
      @parameters = Model.new('Parameters')
    end
    it "allows the creation of a new frame" do

      timing_parameters = @parameters.frame :timing_paramters, 'Timing Parameters' do |frame|
        frame.row :fc_date, 'Date of Financial Close', :date,Date.new(2023,10,1)
        frame.row :construction_months, 'Construction Period', :months, 36
        frame.row :ppa_years, 'PPA Term', :years, 25
        frame.row :cod_date, 'Date of COD', :date do |row|
          frame[:fc_date] >> frame[:construction_months] 
        end
      end

      cost_parameters = @parameters.frame :cost_parameters, 'Costs' do |frame|
        frame.row :epc_cost, 'EPC Contract Cost', :dollar_k, 400000
        
        frame.row :contingency_pct, 'Owners Contingency Percent', :percent, 10.0
        frame.row :contingency, 'Owners Contingency', :dollars_k  do |row|  
          frame[:epc_cost] * (frame[:contingency_pct] / 100)
        end
        
        frame.row :es_cost, 'E&S Costs', :dollar_k, 15000
        
        frame.row :insurance_pct, 'Insurance Percent', :percent, 1.0
        frame.row :insurance, 'Insurance', :dollar_k do |row|  
          frame[:epc_cost] * (frame[:insurance_pct] / 100)
        end
        
        frame.row :owners_engineer_pct, 'Owners Engineer Percent', :percent, 2.0
        frame.row :owners_engineer, 'Owners Engineer', :dollars_k  do |row| 
          frame[:epc_cost] * (frame[:owners_engineer_pct] / 100)
        end

        frame.row :construction_cost, 'Construction Cost', :dollar_k do |row|
          frame[:epc_cost] + 
          frame[:contingency] +
          frame[:es_cost] + 
          frame[:insurance] +
          frame[:owners_engineer]
        end
      end
      @parameters.run

      puts timing_parameters
      puts cost_parameters
    end
  end
end