using XLSX

#--------------------------------Import data file structure-----------------------------------
# 1 - Scenario we are in
# 2 - Folder path for profiles and techno_eco data
# 3 - Data import and location of the data in the excel files (techno_eco, used units, hourly profiles, scenarios/sensitivity)
# 4 - Removal from the imported data of elements not used in the energy system
# 5 - Subsets definition
# 6 - Define scenario data and change the original data file depending on the scenario
# 7 - After scenario/senstivity change, put techno-economics data into vectors
# 8 - Overwrite data for some specific scenario features
# 9 - Put hourly profiles into matrices

#------------------------------- 1 - Scenario we are in---------------------------------------

Scenario_name = All_Scenario_name[N_scen]
Scenario = All_Scenario[N_scen]
Fuel = All_fuel[N_scen]
Year = All_year_data[N_scen]
Profile_name = All_profile_name[N_scen]
Profile_folder_name = All_profile_folder_name[N_scen]
Location = All_location[N_scen]
Electrolyser = All_electrolyser[N_scen]
CO2_capture = All_CO2_capture[N_scen]
if ! isnothing(All_CSP_tech)
    CSP_tech = All_CSP_tech[N_scen]
end
if ! isnothing(All_power_TS)
    Power_TS = All_power_TS[N_scen]
end
csv_files = All_results_folder[N_scen]
Input_data = All_Input_data[N_scen] # Sheet name in the data excel file
Option_max_capacity = All_Option_max_capacity[N_scen]
Option_ramping = All_Option_ramping[N_scen]
Option_no_negative_prices = All_Option_no_negative_prices[N_scen]
Option_fixed_oxygen_sale = All_Option_fixed_oxygen_sale[N_scen]
Option_fixed_heat_sale = All_Option_fixed_heat_sale[N_scen]
Write_flows = All_Write_flows[N_scen]

if isnothing(All_CSP_tech)
    Configuration_scenario = Fuel*"_"*Electrolyser*"_"*CO2_capture
else
    Configuration_scenario = Fuel*"_"*Electrolyser*"_"*CO2_capture*"_"*CSP_tech
end

#-------------------2 - Folder path for profiles and techno_eco data ---------------------------------------
#Techno-economics data
Datafile_techno_economics = joinpath(Inputs_folder,Inputs_file*".xlsx")
#Profile data
Datafile_profile = joinpath(Profiles_folder,Profile_folder_name,Profile_name*".xlsx")

#------3 - Data import and location of the data in the excel files (techno_eco, used units, hourly profiles, scenarios/sensitivity)----------------------------------

#Function to read excel files

function read_xlsx(filename,sheetname)
    sheet = XLSX.readxlsx(filename)[sheetname]
    data = sheet[:]
    data = coalesce.(data,0)  #Replace missing by zero
    return data
end

#Techno-economics and sources (references for data points)

Data_units = read_xlsx(Datafile_techno_economics,Input_data)

#Locate the data in the excel sheet techno eco from the cells "Type of units", "Parameters-->",  "Line/Column index" and subsets
Subsets_index = findfirst(x -> x == "Subsets" , Data_units) # Where is the subset vector
Subsets_2_index = findfirst(x -> x == "Subsets_2" , Data_units)
Subsets_reactant_index = findfirst(x -> x == "Produced from", Data_units)
Units_index = findfirst(x -> x == "Type of units" , Data_units)
Parameters_index = findfirst(x -> x == "Parameters-->" , Data_units)
Year_index = findfirst(x -> x == "Year-->" , Data_units)
Corner_table = findfirst(x -> x == "Line/Column index" , Data_units)
L1 = Corner_table[1] + 1 #First line for data in the excel sheet
C0 = Corner_table[2] #Initial column for data in the excel sheet

#Used units
Data_selected_units =  read_xlsx(Datafile_techno_economics,"Selected_units")

Configuration_index = findfirst(x -> x == "Configuration", Data_selected_units)
L1_c= Configuration_index[1]+1
C0_c = Configuration_index[2]
Configuration_list = Data_selected_units[L1_c-1,C0_c+1:end]

#Fuel produced
Fuel_produced_index = findfirst(x -> x == "Fuel produced", Data_selected_units)
L1_fp= Fuel_produced_index[1]+1
C0_fp = Fuel_produced_index[2]
Fuel_prod_list =  Data_selected_units[L1_fp-1,C0_fp+1:end]

#Fuel energy content LHV (MJ/kg fuel)
Fuel_Energy_content_index = findfirst(x -> x == "Fuel energy content LHV (MJ/kg fuel)", Data_selected_units)
L1_fec= Fuel_Energy_content_index[1]+1
C0_fec = Fuel_Energy_content_index[2]
Fuel_En_cont_list =  Data_selected_units[L1_fec-1,C0_fec+1:end]
#Hourly Profiles

Data_flux_profile =  read_xlsx(Datafile_profile,"Flux")

Locations_flux_index = findfirst(x -> x == "Locations" , Data_flux_profile)
TS_flux_index = (isnothing(findfirst(x -> x == "Profile time series", Data_flux_profile)) ? nothing : findfirst(x -> x == "Profile time series", Data_flux_profile))
Subsets_flux_index = findfirst(x -> x == "Subsets" , Data_flux_profile)
Index_position_flux = findfirst(x -> x == "Index", Data_flux_profile) # To locate where the subset names will be in the excel file
L0_f = Index_position_flux[1]
C0_f = Index_position_flux[2]

Data_price_profile =  read_xlsx(Datafile_profile,"Price")

Locations_price_index = findfirst(x -> x == "Locations" , Data_price_profile)
Subsets_price_index = findfirst(x -> x == "Subsets" , Data_price_profile) #Where are the subsets
Index_position_price = findfirst(x -> x == "Index", Data_price_profile) #Where is the data we need in the excel file, using the word "index" as reference
L0_pr = Index_position_price[1]
C0_pr = Index_position_price[2]

#Scenarios/sensitivity
Data_scenarios_def =  read_xlsx(Datafile_techno_economics,"Scenarios_definition") 

Scenarios_def_index = findfirst(x -> x == "Reference scenario", Data_scenarios_def)
L1_sd= Scenarios_def_index[1]+1
C1_sd = Scenarios_def_index[2]
Scenario_def_parameters = Data_scenarios_def[L1_sd-1,C1_sd:end]

#-----------------------4 - Removal from the imported data of elements not used in the energy system----------------------------------

#Look in the selected unit sheet see which one to remove for this scenario
Name_all_units = Data_units[L1:end,Units_index[2]] ; U_all = length(Name_all_units)
C_Selected_Unit= findfirst(x -> x == Configuration_scenario, Configuration_list)
Selected_Unit = findall(x -> x == 1, Data_selected_units[L1_c:end , C0_c + C_Selected_Unit]) ; U = length(Selected_Unit)
NoSelected_Unit = collect(1:U_all)
NoSelected_Unit = NoSelected_Unit[setdiff(1:end, Selected_Unit), :]

#Look which data year is selected and remove the other columns

Parameters_year = [isa(x, String) ? x : string(x) for x in Data_units[Year_index[1],Year_index[2]+1:end]] ; Y_all = length(Parameters_year)
Selected_years = findall(x -> x == Year || x == "All", Parameters_year)
NoSelected_years = collect(1:Y_all)
NoSelected_years = NoSelected_years[setdiff(1:end, Selected_years), :]

#Put only used units and years in the data_units matrix
Data_units = Data_units[setdiff(1:end, NoSelected_Unit .+ (L1-1)) , setdiff(1:end, NoSelected_years .+ C0)]
Name_selected_units = Data_units[L1:end,Units_index[2]]

#Look which location is selected and remove profile columns not affiliated with this location

All_locations_flux = Data_flux_profile[Locations_flux_index[1],Locations_flux_index[2]+1:end] ; Loc_all_flux = length(All_locations_flux)
Selected_flux = findall(x -> x == Location || x == "All", All_locations_flux)
NoSelected_flux = collect(1:Loc_all_flux)
NoSelected_flux = NoSelected_flux[setdiff(1:end, Selected_flux), :] 
Data_flux_profile = Data_flux_profile[:, setdiff(1:end, NoSelected_flux .+ C0_f)]

#Look which power time series is selected and remove profile columns not affiliated with this location

if ! isnothing(TS_flux_index)
    All_TS_flux = Data_flux_profile[TS_flux_index[1],TS_flux_index[2]+1:end] ; Loc_all_TS = length(All_TS_flux)
    Selected_flux = findall(x -> x == Power_TS || x == "All", All_TS_flux)
    NoSelected_flux = collect(1:Loc_all_TS)
    NoSelected_flux = NoSelected_flux[setdiff(1:end, Selected_flux), :] 
    Data_flux_profile = Data_flux_profile[:, setdiff(1:end, NoSelected_flux .+ C0_f)]
end


#Do the same with electricity price

All_locations_price = Data_price_profile[Locations_price_index[1],Locations_price_index[2]+1:end] ; Loc_all_price = length(All_locations_price)
Selected_price = findall(x -> x == Location || x == "All", All_locations_price)
NoSelected_price = collect(1:Loc_all_price)
NoSelected_price = NoSelected_price[setdiff(1:end, Selected_price), :] 
Data_price_profile = Data_price_profile[:, setdiff(1:end, NoSelected_price .+ C0_pr)]

#------------------------5 - Subsets definition --------------------------------------------
#All subset vectors
Subsets = Data_units[L1:end,Subsets_index[2]] ; nSubsets = length(Subsets)
Subsets_2 = Data_units[L1:end,Subsets_2_index[2]]
Subsets_reactants = Data_units[L1:end,Subsets_reactant_index[2]] ; nSubReac = length(Subsets_reactants)
Subsets_price = Data_price_profile[Subsets_price_index[1],Subsets_price_index[2]+1:end] ; nSubp = length(Subsets_price) # Number of price profiles
Subsets_flux = Data_flux_profile[Subsets_flux_index[1],Subsets_flux_index[2]+1:end] ; nSubf= length(Subsets_flux) # Number of flux profiles

#******************************************************************************
# Subsets related to techno-economics

# Reactant used to produce the main product (chemical reactions)
Reactants = round.(Int,zeros(nSubReac))
for i=1:nSubsets, j=1:nSubReac
    if Subsets[i] == Subsets_reactants[j]
        Reactants[j] = i
    end
end
filter!(x->x!=0,Reactants);R = length(Reactants)

#Main fuel unit (e.g. Ammonia plant)
MainFuel = findall(x -> occursin("MainFuel",x), Subsets_2)
# Power unit that generates electricity
PU = findall(x -> occursin("PU",x), Subsets) # Find all subsets containing "PU"
# Renewable power unit (profile dependent)
RPU = findall(x -> occursin("RPU",x), Subsets) ; nRPU = length(RPU) # Find all subsets containing "RPU"
RPU_p = round.(Int,zeros(nRPU))
for u = 1:nRPU, j=1:nSubf #To make tag profile match tag technology
    if occursin(Subsets_flux[j],Subsets[RPU[u]])
        RPU_p[u] = j
    end
end

#Public grid and district heating
Grid_in = findall(x -> occursin("Grid_in",x), Subsets)
Heat_in = findall(x -> occursin("Heat_in",x), Subsets)
Grid_out = findall(x -> occursin("Grid_out",x), Subsets)
Heat_out = findall(x -> occursin("Heat_out",x), Subsets)
Products = findall(x -> occursin("Product",x), Subsets) ; nProd = length(Products) # Products of the energy system
MinD = findall(x -> occursin("Min_demand",x), Subsets_2) # Products where minimal demands have to be respected)
Tanks = findall(x -> x == "Tank", Subsets) ; nST = length(Tanks) # Storage tank (mass or electrical)
Stor_in = findall(x -> x == "Stor_in", Subsets) # Storage input/output (hydrogen and batteries)
Stor_out = findall(x -> x == "Stor_out", Subsets)

# Hourly purchase of electricity

Grid_buy = findall(x -> x == "Grid_buy", Subsets_2)


#******************************************************************************

# Subsets related to price profiles

#Hourly electricity prices
Grid_buy_p = findall(x -> x == "Grid_buy", Subsets_price) ; nGb = length(Grid_buy_p)
#Fixed heat and oxygen sale
O2_sell = findall(x -> x == "O2_sell", Subsets_2) ; nO2s = length(O2_sell)
Heat_sell = findall(x -> x == "Heat_sell", Subsets_2) ; nHs = length(Heat_sell)


#---6 - Define scenario data and change the original data file depending on the scenario------------------------------------
Parameters_name = Data_units[Parameters_index[1],Parameters_index[2]+1:end] ; nPar = length(Parameters_name) #Base case data parameters
Parameters_year = [isa(x, String) ? x : string(x) for x in Data_units[Year_index[1],Year_index[2]+1:end]] #Base case year parameters

Name_Year = Array{String,1}(undef,nPar)
for i=1:nPar
 Name_Year[i] = Parameters_name[i]*Parameters_year[i] #Concatenate parameter name and year
 if Parameters_year[i] == "All" #Replace All by current year
     Name_Year[i] = Parameters_name[i]*"$Year"
 end
end

#Identify column number depending on the name found in the excel file
C_reference_scenario = findfirst(x -> x == "Reference scenario", Scenario_def_parameters)
C_scenario_def_name = findfirst(x -> x == "Scenario name definition", Scenario_def_parameters)
C_unit_changed = findfirst(x -> x == "Type of units for change", Scenario_def_parameters)
C_parameter_changed = findfirst(x -> x == "Parameter changed", Scenario_def_parameters)
C_year_new_value = findfirst(x -> x == "Year new value", Scenario_def_parameters)
C_new_value = findfirst(x -> x == "New value", Scenario_def_parameters)

Reference_scenario = Data_scenarios_def[L1_sd:end,C1_sd-1 + C_reference_scenario]
Scenario_def_name = Data_scenarios_def[L1_sd:end,C1_sd-1 + C_scenario_def_name]
Current_scen_wo_ref = findall(x -> x==Scenario, Scenario_def_name)
Current_scenario = findall(x -> x == Reference_scenario[Current_scen_wo_ref[1]] || x==Scenario, Scenario_def_name) ; nCurscen = length(Current_scenario) #Also includes the change that have been made in the reference scenario
Unit_changed = Array{String}(undef,nCurscen) ; Parameter_changed = Array{String}(undef,nCurscen) ; Parameters_year_changed = Array{String}(undef,nCurscen)
Year_new_value = Array{String}(undef,nCurscen) ; New_value = zeros(nCurscen)

for i = 1:nCurscen
    Unit_changed[i] =  Data_scenarios_def[L1_sd+Current_scenario[i]-1, C1_sd-1 + C_unit_changed]
    Parameter_changed[i] = Data_scenarios_def[L1_sd+Current_scenario[i]-1, C1_sd-1 + C_parameter_changed]
    Year_new_value[i] =  string(Data_scenarios_def[L1_sd+Current_scenario[i]-1, C1_sd-1 + C_year_new_value])
    #Data_scenarios_def[L1_sd+Current_scenario[i]-1, C1_sd-1 + C_year_new_value]
    New_value[i] = Data_scenarios_def[L1_sd+Current_scenario[i]-1, C1_sd-1 + C_new_value]
    Parameters_year_changed[i] = Parameter_changed[i]*Year_new_value[i]
    if Year_new_value[i] == "All"
        Parameters_year_changed[i] = Parameter_changed[i]*"$Year"
    end
end

# Change values for this scenario year if year new value = year scenario or all
C_to_change = round.(Int,zeros(nCurscen))
L_to_change = round.(Int,zeros(nCurscen)) #Line units to change
for i=1:nCurscen
    #Change Data_units at special coordinate with new_value for a specific scenario
    for j=1:nPar
        if Parameters_year_changed[i] == Name_Year[j]
            C_to_change[i] = j
        end
    end
    for u=1:U
        if Unit_changed[i] == Name_selected_units[u]
            L_to_change[i] = u
        end
    end
    if L_to_change[i] !=0 && C_to_change[i] !=0
        Data_units[L1-1+L_to_change[i],C0 + C_to_change[i]] = New_value[i]
    end
end

#---- 7 - Put techno-economics data after scenario/sensitivity change into vectors-------------------------

# Get the column index by comparing the name to the one in the excel file: they have to be the same !
C_Fuel_energy_content = findfirst(x -> x == Fuel, Fuel_prod_list)
C_Used_Unit = findfirst(x -> x == "Used (1 or 0)", Parameters_name)
C_Unit_tag = findfirst(x -> x == "Unit tag", Parameters_name)
C_demand = findfirst(x -> x == "Yearly demand (kg fuel)", Parameters_name)
C_H2_balance = findfirst(x -> x == "H2 balance", Parameters_name)
C_El_balance = findfirst(x -> x == "El balance", Parameters_name)
C_Heat_balance = findfirst(x -> x == "Heat balance", Parameters_name)
C_CSP_balance = findfirst(x -> x == "CSP balance", Parameters_name)
C_Max_Cap = findfirst(x -> x == "Max Capacity", Parameters_name)
C_Load_min = findfirst(x -> x == "Load min (% of max capacity)", Parameters_name)
C_Ramp_up = findfirst(x -> x == "Ramp up (% of capacity /h)", Parameters_name)
C_Ramp_down = findfirst(x -> x == "Ramp down (% of capacity /h)", Parameters_name)
C_Heat_generated = findfirst(x -> x == "Heat generated (kWh/output)", Parameters_name)
C_Sc_nom = findfirst(x -> x == "Electrical consumption (kWh/output)", Parameters_name)
C_Prod_rate = findfirst(x -> x == "Fuel production rate (kg output/kg input)", Parameters_name)
C_invest = findfirst(x -> x == "Investment (EUR/Capacity installed)", Parameters_name)
C_FixOM = findfirst(x -> x == "Fixed cost (EUR/Capacity installed/y)", Parameters_name)
C_VarOM = findfirst(x -> x == "Variable cost (EUR/output)", Parameters_name)
C_FSp = findfirst(x -> x == "Fuel selling price (EUR/output)", Parameters_name)
C_FBp = findfirst(x -> x == "Fuel buying price (EUR/output)", Parameters_name)
C_annuity = findfirst(x -> x == "Annuity factor", Parameters_name)

#Data recovery using techno-economics data file: from L1 to end at column x: check if variable corresponds in the excel file !!
#Units are indicated in the Excel file
Used_Unit = Data_units[L1:end , C0 + C_Used_Unit] # Indicate if the unit is used in the energy system or not
Unit_tag = Array{String}(Data_units[L1:end, C0 + C_Unit_tag])  # Head-lines for the output csv file
Fuel_energy_content = Fuel_En_cont_list[C_Fuel_energy_content] # Get the fuel energy content of the fuel in the current scenario
H2_balance = Data_units[L1:end , C0 + C_H2_balance]
El_balance = Data_units[L1:end , C0 + C_El_balance]
CSP_balance = (isnothing(C_CSP_balance) ? nothing : Data_units[L1:end , C0 + C_CSP_balance])
Heat_balance = Data_units[L1:end, C0 + C_Heat_balance]
Heat_generated = Data_units[L1:end, C0 + C_Heat_generated] #Excess that can be recovered per unit
Max_Cap = Data_units[L1:end , C0 + C_Max_Cap] # Maximum capacity that can be installed per element of the energy system
Load_min = Data_units[L1:end , C0 + C_Load_min] # Minimum load of the unit
Ramp_up = Data_units[L1:end , C0 + C_Ramp_up] # Ramp rate upward
Ramp_down = Data_units[L1:end , C0 + C_Ramp_down] # Ramp rate downward
Sc_nom = Data_units[L1:end , C0 + C_Sc_nom] # Specific electrical consumption
Prod_rate = Data_units[L1:end,C0 + C_Prod_rate] # Fuel production
Invest = Data_units[L1:end , C0 + C_invest] #Investment cost
FixOM = Data_units[L1:end , C0 + C_FixOM] #Fixed operation and maintenance costs
VarOM = Data_units[L1:end , C0 + C_VarOM] #Variable operation and maintenance costs
Fuel_Selling_fixed = Data_units[L1:end , C0 + C_FSp] #Selling price of the output fuel for each unit
Fuel_Buying_fixed = Data_units[L1:end,C0 + C_FBp] #Fixed fuel buying price
Demand = Data_units[L1:end,C0 + C_demand] #Output fuel demand
Annuity_factor = Data_units[L1:end,C0 + C_annuity] #Check the Excel for detailled calculations

#------8 - Overwrite data for some specific scenario features-------------------

if Option_fixed_heat_sale == false
    for i=1:nHs
        Fuel_Selling_fixed[Heat_sell[i]] = 0
    end
end

if Option_fixed_oxygen_sale == false
    for i=1:nO2s
        Fuel_Selling_fixed[O2_sell[i]] = 0
    end
end

#---- 10 - Put profiles into matrices -------------------------

#******************************************************************************
#Flux profiles
Flux_Profile = zeros(nSubf,T)
for i = 1:nSubf, t=1:T
    Flux_Profile[i,t] = Data_flux_profile[L0_f+Time[t], C0_f+i]
end
#******************************************************************************
# Price profiles
Price_Profile = zeros(nSubp,T)
for i = 1:nSubp, t=1:T
    Price_Profile[i,t] = Data_price_profile[L0_pr+Time[t],C0_pr+i]
    # Get the profile with corresponding index
end

for i = 1:nSubp, t=1:T
    if Option_no_negative_prices == true
        if Price_Profile[i,t] < 0
            Price_Profile[i,t] = 0
        end
    end
end