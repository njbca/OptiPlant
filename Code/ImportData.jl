using ExcelReaders

Scenario_name = All_Scenario_name[N_scen]
Scenario = All_Scenario[N_scen]
Fuel = All_fuel[N_scen]
Year = All_year[N_scen]
Location = All_location[N_scen]
Electrolyser = All_electrolyser[N_scen]
csv_files = All_results_folder[N_scen]
Input_data = All_Input_data[N_scen] # Sheet name in the data excel file
Profile_name = All_Profile_name[N_scen]
Option_ramping = All_Option_ramping[N_scen]
Option_no_negative_prices = All_Option_no_negative_prices[N_scen]
Option_fixed_oxygen_sale = All_Option_fixed_oxygen_sale[N_scen]
Option_fixed_heat_sale = All_Option_fixed_heat_sale[N_scen]
Write_flows = All_Write_flows[N_scen]

Configuration_scenario = Fuel*"_"*Electrolyser

#---------------------------------Folder path---------------------------------------
#Techno-economics data
Datafile_techno_economics = joinpath(Inputs_folder,Project*"_"*Inputs_file*".xlsx")
#Profile data
Datafile_profile = joinpath(Profile_folder,Profile_name,Profile_name*".xlsx") #Sheet name in the excel file

#--------------------------------Data reading----------------------------------

#Techno-economics
Data_units = readxlsheet(Datafile_techno_economics,Input_data)

#Locate the data in the excel sheet techno eco from the cells "Type of units", "Parameters-->"
# ,  "Line/Column index" and subsets

Subsets_index = findfirst(x -> x == "Subsets" , Data_units)
Subsets_2_index = findfirst(x -> x == "Subsets_2" , Data_units)
Subsets_reactant_index = findfirst(x -> x == "Produced from", Data_units)
Units_index = findfirst(x -> x == "Type of units" , Data_units)
Parameters_index = findfirst(x -> x == "Parameters-->" , Data_units)
Year_index = findfirst(x -> x == "Year-->" , Data_units)
Corner_table = findfirst(x -> x == "Line/Column index" , Data_units)
L1 = Corner_table[1] + 1 #First line for data in the excel sheet
C0 = Corner_table[2] #Initial column for data in the excel sheet

#Used units
Data_selected_units = readxlsheet(Datafile_techno_economics,"Selected_units")
Configuration_index = findfirst(x -> x == "Configuration", Data_selected_units)
L1_c= Configuration_index[1]+1
C0_c = Configuration_index[2]
Configuration_list = Data_selected_units[L1_c-1,C0_c+1:end]

#Profiles

Data_flux_profile = readxlsheet(Datafile_profile,"Flux")
Data_price_profile = readxlsheet(Datafile_profile,"Price")

Index_position_flux = findfirst(x -> x == "Index", Data_flux_profile)
L0_f = Index_position_flux[1]
C0_f = Index_position_flux[2]

Index_position_price = findfirst(x -> x == "Index", Data_price_profile)
L0_pr = Index_position_price[1]
C0_pr = Index_position_price[2]

Subsets_price_index = findfirst(x -> x == "Subsets" , Data_price_profile)
Subsets_flux_index = findfirst(x -> x == "Subsets" , Data_flux_profile)

#Scenarios/sensitivity
Data_scenarios_def = readxlsheet(Datafile_techno_economics,"Scenarios_definition")
Scenarios_def_index = findfirst(x -> x == "Scenarios definition", Data_scenarios_def)
L1_sd= Scenarios_def_index[1]+1
C0_sd = Scenarios_def_index[2]
Scenario_def_parameters = Data_scenarios_def[L1_sd-1,C0_sd+1:end]

#----------------------------Elements that can be used in the energy system----------------------------------

Name_all_units = Data_units[L1:end,Units_index[2]] ; U_all = length(Name_all_units)
C_Selected_Unit= findfirst(x -> x == Configuration_scenario, Configuration_list)
Selected_Unit = findall(x -> x == 1, Data_selected_units[L1_c:end , C0_c + C_Selected_Unit]) ; U = length(Selected_Unit)
NoSelected_Unit = collect(1:U_all)
NoSelected_Unit = NoSelected_Unit[setdiff(1:end, Selected_Unit), :]

#Put only used units in the data_units matrix
Data_units = Data_units[setdiff(1:end, NoSelected_Unit .+ (L1-1)), :]
Name_selected_units = Data_units[L1:end,Units_index[2]]

#---------------------------Subsets definition : Names have to correspond with the Excel file !
Subsets = Data_units[L1:end,Subsets_index[2]] ; nSubsets = length(Subsets)
Subsets_2 = Data_units[L1:end,Subsets_2_index[2]]
Subsets_reactants = Data_units[L1:end,Subsets_reactant_index[2]] ; nSubReac = length(Subsets_reactants)
Subsets_price = Data_price_profile[Subsets_price_index[1],Subsets_price_index[2]+1:end]
Subsets_flux = Data_flux_profile[Subsets_flux_index[1],Subsets_flux_index[2]+1:end] ; nSubf= length(Subsets_flux) # Number of flux profiles

#---------------------------------Subsets techno-economics------------------------
# Reactant used to produce the main product (chemical reactions)
Reactants = round.(Int,zeros(nSubReac))
for i=1:nSubsets, j=1:nSubReac
    if Subsets[i] == Subsets_reactants[j]
        Reactants[j] = i
    end
end
filter!(x->x!=0,Reactants);R = length(Reactants)

# Power unit
PU = findall(x -> occursin("PU",x), Subsets) # Find all subsets containing "PU"
# Renewable power unit (profile dependent)
RPU = findall(x -> occursin("RPU",x), Subsets) ; nRPU = length(RPU) # Find all subsets containing "PU"
RPU_p = round.(Int,zeros(nRPU))
for u = 1:nRPU, j=1:nSubf #To make tag profile match tag technology
    if occursin(Subsets_flux[j],Subsets[RPU[u]])
        RPU_p[u] = j
    end
end

#Public grid and district heating
Grid_in = findall(x -> occursin("Grid_in",x), Subsets)
GPU = vcat(RPU,Grid_in) # Generation power unit
Heat_in = findall(x -> occursin("Heat_in",x), Subsets)
Grid_out = findall(x -> occursin("Grid_out",x), Subsets)
Heat_out = findall(x -> occursin("Heat_out",x), Subsets)
Products = findall(x -> occursin("Product",x), Subsets) ; nProd = length(Products) # Products of the energy system
MinD = findall(x -> x == "Min_demand", Subsets_2) # Products where minimal demands have to be respected)
Tanks = findall(x -> x == "Tank", Subsets) ; nST = length(Tanks) # Storage tank (mass or electrical)
Stor_in = findall(x -> x == "Stor_in", Subsets) # Storage input/output
Stor_out = findall(x -> x == "Stor_out", Subsets)

#-----------------------------------Price data----------------------------
#Hourly electricity prices
Grid_buy_p = findall(x -> x == "Grid_buy", Subsets_price) ; nGb = length(Grid_buy_p)
#Fixed electricity prices
Grid_buy = findall(x -> x == "Grid_buy", Subsets_2)
#Fixed heat and oxygen sale
O2_sell = findall(x -> x == "O2_sell", Subsets_2) ; nO2s = length(O2_sell)
Heat_sell = findall(x -> x == "Heat_sell", Subsets_2) ; nHs = length(Heat_sell)

#------------------------------------------Scenario data---------------------------------------
Parameters_name = Data_units[Parameters_index[1],Parameters_index[2]+1:end] ; nPar = length(Parameters_name) #Base case data parameters
Parameters_year = Data_units[Year_index[1],Year_index[2]+1:end]

Name_Year = Array{String,1}(undef,nPar)
for i=1:nPar
 Name_Year[i] = Parameters_name[i]*Parameters_year[i]
end

C_scenario_def_name = findfirst(x -> x == "Scenario name definition", Scenario_def_parameters)
C_unit_changed = findfirst(x -> x == "Type of units for change", Scenario_def_parameters)
C_parameter_changed = findfirst(x -> x == "Parameter changed", Scenario_def_parameters)
C_year_new_value = findfirst(x -> x == "Year new value", Scenario_def_parameters)
C_new_value = findfirst(x -> x == "New value", Scenario_def_parameters)

Scenario_def_name = Data_scenarios_def[L1_sd:end,C0_sd + C_scenario_def_name]
Current_scenario = findall(x -> x == Scenario, Scenario_def_name) ; nCurscen = length(Current_scenario)
Unit_changed = Array{String}(undef,nCurscen) ; Parameter_changed = Array{String}(undef,nCurscen) ; Parameters_year_changed = Array{String}(undef,nCurscen)
Year_new_value = Array{String}(undef,nCurscen) ; New_value = zeros(nCurscen)
for i = 1:nCurscen
    Unit_changed[i] =  Data_scenarios_def[L1_sd+Current_scenario[i]-1, C0_sd + C_unit_changed]
    Parameter_changed[i] = Data_scenarios_def[L1_sd+Current_scenario[i]-1, C0_sd + C_parameter_changed]
    Year_new_value[i] = Data_scenarios_def[L1_sd+Current_scenario[i]-1, C0_sd + C_year_new_value]
    New_value[i] = Data_scenarios_def[L1_sd+Current_scenario[i]-1, C0_sd + C_new_value]
    Parameters_year_changed[i] = Parameter_changed[i]*Year_new_value[i]
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
    Data_units[L1-1+L_to_change[i],C0 + C_to_change[i]] = New_value[i]
end

#--------------------------------#Techno-economics data-------------------------

# Get the column index by comparing the name to the one in the excel file: they have to be the same !
C_Used_Unit = findfirst(x -> x == "Used (1 or 0)", Parameters_name)
C_Unit_tag = findfirst(x -> x == "Unit tag", Parameters_name)
C_demand = findfirst(x -> x == "Yearly demand (kg fuel)", Parameters_name)
C_H2_balance = findfirst(x -> x == "H2 balance"*"$Year", Name_Year)
C_El_balance = findfirst(x -> x == "El balance", Parameters_name)
C_Heat_balance = findfirst(x -> x == "Heat balance", Parameters_name)
C_Load_min = findfirst(x -> x == "Load min (% of max capacity)"*"$Year", Name_Year)
C_Load_max = findfirst(x -> x == "Load max (% of max capacity)"*"$Year", Name_Year)
C_Ramp_up = findfirst(x -> x == "Ramp up (% of capacity /h)"*"$Year", Name_Year)
C_Ramp_down = findfirst(x -> x == "Ramp down (% of capacity /h)"*"$Year", Name_Year)
C_Heat_generated = findfirst(x -> x == "Heat generated (kWh/output)"*"$Year", Name_Year)
C_Sc_nom = findfirst(x -> x == "Electrical consumption (kWh/output)"*"$Year", Name_Year)
C_Prod_rate = findfirst(x -> x == "Fuel production rate (kg output/kg input)"*"$Year", Name_Year)
C_invest = findfirst(x -> x == "Investment (€/Capacity installed)"*"$Year", Name_Year)
C_FixOM = findfirst(x -> x == "Fixed cost (€/Capacity installed/y)"*"$Year", Name_Year)
C_VarOM = findfirst(x -> x == "Variable cost (€/Output)"*"$Year", Name_Year)
C_FSp = findfirst(x -> x == "Fuel selling price (€/output)"*"$Year", Name_Year)
C_FBp = findfirst(x -> x == "Fuel buying price (€/output)"*"$Year", Name_Year)
C_annuity = findfirst(x -> x == "Annuity factor"*"$Year", Name_Year)

#Data recovery using techno-economics data file: from L1 to end at column x: check if variable corresponds in the excel file !!
#Units are indicated in the Excel file
Used_Unit = Data_units[L1:end , C0 + C_Used_Unit] # Indicate if the unit is used in the energy system or not
Unit_tag = Array{String}(Data_units[L1:end, C0 + C_Unit_tag])  # Head-lines for the output csv file
H2_balance = Data_units[L1:end , C0 + C_H2_balance]
El_balance = Data_units[L1:end , C0 + C_El_balance]
Heat_balance = Data_units[L1:end, C0 + C_Heat_balance]
Heat_generated = Data_units[L1:end, C0 + C_Heat_generated]
Load_min = Data_units[L1:end , C0 + C_Load_min] # Minimum load of the unit
Load_max = Data_units[L1:end , C0 + C_Load_max]
Ramp_up = Data_units[L1:end , C0 + C_Ramp_up]
Ramp_down = Data_units[L1:end , C0 + C_Ramp_down]
Sc_nom = Data_units[L1:end , C0 + C_Sc_nom] # Specific electrical consumption
Prod_rate = Data_units[L1:end,C0 + C_Prod_rate]; #filter!(x->x!=0,Prod_rate) # Fuel production
Invest = Data_units[L1:end , C0 + C_invest] #Investment cost
FixOM = Data_units[L1:end , C0 + C_FixOM] #Fixed operation and maintenance costs
VarOM = Data_units[L1:end , C0 + C_VarOM] #Variable operation and maintenance costs
Fuel_Selling_fixed = Data_units[L1:end , C0 + C_FSp] #Selling price of the output fuel for each unit
Fuel_Buying_fixed = Data_units[L1:end,C0 + C_FBp] #Fixed fuel buying price
Demand = Data_units[L1:end,C0 + C_demand] #Output fuel demand
Annuity_factor = Data_units[L1:end,C0 + C_annuity] #Check the Excel for detailled calculations

#-------------------------------------- Scenarios data -------------------------------------------
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

#-------------------------------Flux Profiles -------------------------

Flux_Profile = zeros(nSubf,T)
for u = 1:nSubf, t=1:T
    Flux_Profile[u,t] = Data_flux_profile[L0_f+Time[t], C0_f+u]
end
#----------------------------Price profiles--------------------------

nSubp = length(Subsets_price) # Number of price profiles

Price_Profile = zeros(nSubp,T)
for u = 1:nSubp, t=1:T
    Price_Profile[u,t] = Data_price_profile[L0_pr+Time[t],C0_pr+u]
    # Get the profile with corresponding index
end

for u = 1:nSubp, t=1:T
    if Option_no_negative_prices == true
        if Price_Profile[u,t] < 0
            Price_Profile[u,t] = 0
        end
    end
end
