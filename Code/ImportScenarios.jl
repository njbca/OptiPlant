using XLSX, DataFrames

Datafile_inputs = joinpath(Inputs_folder,Inputs_file*".xlsx")

function read_xlsx(filename,sheetname)
    sheet = XLSX.readxlsx(filename)[sheetname]
    data = sheet[:]
    data = coalesce.(data,0)  #Replace missing by zero
    return data
end

Data_scenarios = read_xlsx(Datafile_inputs,Scenarios_set)

#Get inputs from the scenario sheet
L1_scenario = findfirst(x -> x == "Scenario number", Data_scenarios)[1] + 1

C_Scenario_name = findfirst(x -> x == "Scenario name", Data_scenarios)[2]
C_Scenario = findfirst(x -> x == "Scenario", Data_scenarios)[2]
C_location = findfirst(x -> x == "Location", Data_scenarios)[2]
C_fuel = findfirst(x -> x == "Fuel", Data_scenarios)[2]
C_CO2_capture = findfirst(x -> x == "CO2 capture", Data_scenarios)[2]
C_CSP_tech = (isnothing(findfirst(x -> x == "CSP tech", Data_scenarios)) ? nothing : findfirst(x -> x == "CSP tech", Data_scenarios)[2])
C_year_data = findfirst(x -> x == "Year data", Data_scenarios)[2]
C_profile_folder_name = findfirst(x -> x == "Profile folder name", Data_scenarios)[2]
C_name_profile = findfirst(x -> x == "Profile name", Data_scenarios)[2]
C_power_TS = (isnothing(findfirst(x -> x == "Profile time series", Data_scenarios)) ? nothing : findfirst(x -> x == "Profile time series", Data_scenarios)[2])
C_electrolyser = findfirst(x -> x == "Electrolyser", Data_scenarios)[2]
C_input_data = findfirst(x -> x == "Input data sheet", Data_scenarios)[2]

C_results_folder = findfirst(x -> x == "Result folder name", Data_scenarios)[2]
C_max_capacity = findfirst(x -> x == "Max capacity", Data_scenarios)[2]
C_ramping = findfirst(x -> x == "Ramping", Data_scenarios)[2]
C_no_negative_elec_price = findfirst(x -> x == "No negative elec price", Data_scenarios)[2]
C_fixed_oxygen_sale = findfirst(x -> x == "Fixed oxygen sale", Data_scenarios)[2]
C_fixed_heat_sale = findfirst(x -> x == "Fixed heat sale", Data_scenarios)[2]
C_flows = findfirst(x -> x == "Flows", Data_scenarios)[2]

All_Scenario_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_Scenario_name]]
All_Scenario = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_Scenario]] ; N_scenarios = length(All_Scenario)
All_location = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_location]]
All_fuel = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_fuel]]
All_CO2_capture = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_CO2_capture]]
All_CSP_tech = (isnothing(C_CSP_tech) ? nothing : [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_CSP_tech]])
All_year_data = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_year_data]]
All_profile_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_name_profile]]
All_profile_folder_name = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_profile_folder_name]]
All_power_TS = (isnothing(C_power_TS) ? nothing : [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_power_TS]])
All_electrolyser = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_electrolyser]]
All_Input_data = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_input_data]]
All_results_folder = [isa(x, String) ? x : string(x) for x in Data_scenarios[L1_scenario:end , C_results_folder]]

# Add a maximum capacity constraint (has to be true for maximal profit or when selling electricity )
All_Option_max_capacity = Data_scenarios[L1_scenario:end , C_max_capacity]
# Add ramping constraints (higher computational time)
All_Option_ramping = Data_scenarios[L1_scenario:end , C_ramping]
# Replace negative electricity prices with 0
All_Option_no_negative_prices = Data_scenarios[L1_scenario:end , C_no_negative_elec_price]

#Oxygen and heat sale
All_Option_fixed_oxygen_sale = Data_scenarios[L1_scenario:end , C_fixed_oxygen_sale]
All_Option_fixed_heat_sale = Data_scenarios[L1_scenario:end , C_fixed_heat_sale]

# Results that you want to write

All_Write_flows = Data_scenarios[L1_scenario:end , C_flows]
