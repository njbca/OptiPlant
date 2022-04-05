using ExcelReaders

Datafile_inputs = joinpath(Inputs_folder,Project*"_"*Inputs_file*".xls")
Data_scenarios = readxlsheet(Datafile_inputs,Scenarios_set)

L1_scenario = findfirst(x -> x == "Scenario number", Data_scenarios)[1] + 1

C_Scenario_name = findfirst(x -> x == "Scenario name", Data_scenarios)[2]
C_Scenario = findfirst(x -> x == "Scenario", Data_scenarios)[2]
C_location = findfirst(x -> x == "Location", Data_scenarios)[2]
C_fuel = findfirst(x -> x == "Fuel", Data_scenarios)[2]
C_year = findfirst(x -> x == "Year", Data_scenarios)[2]
C_electrolyser = findfirst(x -> x == "Electrolyser", Data_scenarios)[2]
C_input_data = findfirst(x -> x == "Input data sheet", Data_scenarios)[2]
C_profile_name = findfirst(x -> x == "Profile name", Data_scenarios)[2]
C_results_folder = findfirst(x -> x == "Result folder name", Data_scenarios)[2]
C_ramping = findfirst(x -> x == "Ramping", Data_scenarios)[2]
C_no_negative_elec_price = findfirst(x -> x == "No negative elec price", Data_scenarios)[2]
C_fixed_oxygen_sale = findfirst(x -> x == "Fixed oxygen sale", Data_scenarios)[2]
C_fixed_heat_sale = findfirst(x -> x == "Fixed heat sale", Data_scenarios)[2]
C_flows = findfirst(x -> x == "Flows", Data_scenarios)[2]

All_Scenario_name = Array{String}(Data_scenarios[L1_scenario:end , C_Scenario_name])
All_Scenario = Array{String}(Data_scenarios[L1_scenario:end , C_Scenario]) ; N_scenarios = length(All_Scenario)
All_location = Array{String}(Data_scenarios[L1_scenario:end , C_location])
All_fuel = Array{String}(Data_scenarios[L1_scenario:end , C_fuel])
All_year = round.(Int,Data_scenarios[L1_scenario:end , C_year])
All_electrolyser = Array{String}(Data_scenarios[L1_scenario:end , C_electrolyser])
All_results_folder = Array{String}(Data_scenarios[L1_scenario:end , C_results_folder])

All_Input_data = Array{String}(Data_scenarios[L1_scenario:end , C_input_data])
All_Profile_name = Array{String}(Data_scenarios[L1_scenario:end , C_profile_name])
# Add ramping constraints (higher computational time)
All_Option_ramping = Data_scenarios[L1_scenario:end , C_ramping]
# Replace negative electricity prices with 0
All_Option_no_negative_prices = Data_scenarios[L1_scenario:end , C_no_negative_elec_price]
#Oxygen and heat sale
All_Option_fixed_oxygen_sale = Data_scenarios[L1_scenario:end , C_fixed_oxygen_sale]
All_Option_fixed_heat_sale = Data_scenarios[L1_scenario:end , C_fixed_heat_sale]

# Results that you want to write
All_Write_flows = Data_scenarios[L1_scenario:end , C_flows]
