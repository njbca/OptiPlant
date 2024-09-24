using JuMP, CSV, DataFrames, XLSX

#Choose a solver
Solver = "Gurobi" #Write "Gurobi" or "HiGHS".

#Load corresponding package
if Solver == "Gurobi" 
  using Gurobi
else
  using HiGHS
end
 

#Open julia terminal with VS Code: Alt J Alt O 

#------------------------------Problem set up------------------------------------
#Project name
Project = "Base"
# Folder name for all csv file
all_csv_files = "All_results"
# Folder paths for data acquisition and writing
Main_folder = "C:/Users/njbca/Documents/Models/OptiPlantGitHub"
#Main_folder = "C:/.../OptiPlant-master/OptiPlant-master" ; #Fill with your own Optiplant folder location
Profiles_folder = joinpath(Main_folder,Project,"Data","Profiles") ;
Inputs_folder = joinpath(Main_folder,Project,"Data","Inputs") ; 
Inputs_file = "Meas_vs_sim_data"
# Scenario set (same name as exceel sheet)
Scenarios_set =  "ScenariosToRun" ; include("ImportScenarios.jl")
# Scenario under study (all between N_scen_0 and N_scen_end)
N_scen_0 = 82 ; N_scen_end = N_scenarios # or N_scen_end = N_scenarios for total number of scenarios
#Studied hours (max 8760). When there is maintenance hours are out
#TMend = 4000-4876 : 90% time working ; T = 4000-4761 : 8000 hours ; T=4675-5011 : 2 weeks maintenance in summer
TMstart = 4000 ; TMend = 4001 ; Tbegin = 240 ; Tfinish=8712 #Time maintenance starts/end ; Tbegin: Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
Time = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ; T = length(Time)
Tstart = vcat(collect(1:TMstart),collect(TMend:Tfinish)) ;
if Tbegin >= 2
  splice!(Tstart,1:Tbegin) # Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
end
Currency_factor = 1 # 1.12 for dollar 2019 #All input data are in Euro 2019

#--------------------- Main code -------------------------
N_scen = N_scen_0

while N_scen < N_scen_end + 1 #Run the optimization model for all scenarios

  include("ImportData.jl") # Import data
  Flows_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Flows") ; mkpath(Flows_result_folder)
  Main_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Main results") ; mkpath(Main_result_folder)
  Main_all_results_folder = joinpath(Main_folder,Project,"Results",all_csv_files,"Main results") ; mkpath(Main_all_results_folder)
  Data_used_folder = joinpath(Main_folder,Project,"Results",csv_files,"Data used") ; mkpath(Data_used_folder)
  #-----------------------------------Model----------------------------------
  
  if Solver == "Gurobi"
    Model_LP = Model(Gurobi.Optimizer)
  else
    Model_LP = Model(HiGHS.Optimizer)
  end
  #
  
  #Decision variables
  @variable(Model_LP,Costs) # In €2019 by default
  @variable(Model_LP,X[1:U,t in Time] >= 0) # Products and energy flow (kg/h for unit with "physical" output or kW for electrical units)
  @variable(Model_LP,Capacity[1:U] >=0) #  Production capacity of each unit (kg/h or kW)
  @variable(Model_LP,Sold[1:U,t in Time] >= 0) # Quantity of products sold (kg/h or kW)
  @variable(Model_LP,Bought[1:U,t in Time] >= 0) # Quantity of input bought (kg/h or kW)


  # Set higher bound to 0 for not used units
  for t in Time, u=1:U
    if Used_Unit[u]==0
      @constraint(Model_LP,X[u,t] <= 0)
      @constraint(Model_LP,Capacity[u] <= 0)
      @constraint(Model_LP,Sold[u,t] <= 0)
      @constraint(Model_LP,Bought[u,t] <= 0)
    end
  end

  #Objective function (cost minimization)

 #Minimize the total cost of the system
 @objective(Model_LP, Min, Costs)

 #Costs equation
 @constraint(Model_LP, Costs == sum(Fuel_Buying_fixed[u]*Bought[u,t] for u=1:U, t in Time)
 + sum(Price_Profile[Grid_buy_p[u],t]*Bought[Grid_buy[u],Time[t]] for u=1:nGb,t=1:T)
 + sum((Invest[u]*Annuity_factor[u] + FixOM[u])*Capacity[u] for u=1:U)
 + sum(VarOM[u] * X[u,t] for u=1:U,t in Time)
 - sum(Fuel_Selling_fixed[u]*Sold[u,t] for u=1:U,t in Time)
 )

  #Yearly demand: have to fullfill min yearly demand if there is one
  @constraint(Model_LP,[i in MinD], sum(Sold[i,t] for t in Time) == Demand[i])

  #Capacity constraints

  if Option_max_capacity == true
    @constraint(Model_LP,[u=1:U], Capacity[u] <= Max_Cap[u]) #Maximal capacity that can be installed
  end

  #Load constraints:

  @constraint(Model_LP,[u=1:U,t in Tstart], X[u,t] >= Capacity[u]*Load_min[u]) #Min flow
  @constraint(Model_LP,[u=1:U,t in Time], X[u,t] <= Capacity[u]) #Max flow

  #Ramping constraints
  if Option_ramping == true

    @constraint(Model_LP,[u=1:U,t=1:T], X[u,Time[t]]-(t>Time[1] ? X[u,Time[t-1]] : 0) <= Ramp_up[u]*Capacity[u])
    @constraint(Model_LP,[u=1:U,t=1:T], (t>Time[1] ? X[u,Time[t-1]] : 0)-X[u,Time[t]] <= Ramp_down[u]*Capacity[u])

  end

  # Productions rates

  @constraint(Model_LP,[i=1:nProd,t in Time], X[Products[i],t] == X[Reactants[i],t]*Prod_rate[Products[i]])
  # Hydrogen balance
  @constraint(Model_LP,[t in Time],sum(H2_balance[u]*X[u,t] for u=1:U)==0)
  # Heat balance
  @constraint(Model_LP,[t in Time],sum(Heat_balance[u]*Heat_generated[u]*X[u,t] for u=1:U)==0)
  # CSP balance
  if ! isnothing(CSP_balance)
  @constraint(Model_LP,[t in Time], sum(CSP_balance[u]*X[u,t] for u=1:U)==0)
  end
  # Storages balance
  @constraint(Model_LP,[i=1:nST,t=1:T], X[Tanks[i],Time[t]] == (t>Time[1] ? X[Tanks[i],Time[t-1]] : 0) + X[Stor_in[i],Time[t]] - X[Stor_out[i],Time[t]])

  # Renewable energy production constraint (profile dependent)
  @constraint(Model_LP, [i = 1:nRPU,t=1:T], X[RPU[i],Time[t]] == Flux_Profile[RPU_p[i],t]*Capacity[RPU[i]])

  # Electricity produced and consumed have to be at equilibrium
  @constraint(Model_LP, [t in Time], sum(El_balance[u]*X[u,t] for u=1:U) ==
  sum(Sc_nom[u]*X[u,t] for u=1:U))

  # Sold and bought ouputs/inputs
  @constraint(Model_LP,[u=1:U,t in Time],Sold[u,t] <= X[u,t]) # Have to sell less than what is produced
  @constraint(Model_LP,[u=1:U,t in Time],Bought[u,t] == X[u,t]) # Have to buy exactly what you use

  # solve
  optimize!(Model_LP)
 
  #Start counter
  #start_time = time_ns()
  
  #--------------------------Results output------------------------------------------
  if termination_status(Model_LP) == MOI.OPTIMAL

    #----------------Variable flows and total specific consumption -------------
    Infos = Array{String,1}(undef,T)
    Infos[1] = "Scenario: "*Scenario_name
    Infos[2] = "Year data: "*"$Year"
    Infos[2] = "Profile: "*Profile_name
    Infos[3] = "Location: "*Location
    Infos[4] = "Fuel: "*Fuel
    Infos[5] = "Electrolyser: "*Electrolyser
    Infos[6] = "CO2 capture: "*CO2_capture
    if ! isnothing(All_CSP_tech)
      Infos[7] = "CSP tech: "*CSP_tech
    else
      Infos[7] = " "
    end

    if ! isnothing(All_power_TS)
      Infos[7] = "Power time series: "*Power_TS
    else
      Infos[7] = " "
    end

    for i=8:T
      Infos[i] = " "
    end

    if Write_flows == true
      #Total electricity consumption
      Sc_tot = zeros(T)
      for t=1:T
          Sc_tot[t] = sum(Sc_nom[u]*JuMP.value.(X[u,Time[t]]) for u=1:U)
      end
      # Flows
      Solution_X = zeros(T,U)
      for u=1:U, t=1:T
          Solution_X[t,u] = JuMP.value.(X[u,Time[t]])
      end
      df_flow = DataFrame([Infos Time Solution_X Sc_tot],:auto)
      #Headlines
      rename!(df_flow,["Informations";"Time";Unit_tag;"Electricity consumption"])
      #File name
      flows = "F_$N_scen.csv"
      #Write the Csv file
      CSV.write(joinpath(Flows_result_folder,flows),df_flow)
    end

    #-----------------------Techno_economical data and sources used------------------------

    df_techno_eco = DataFrame(Data_units[Parameters_index[1]:end,Subsets_index[2]:end], :auto)
    techno_eco = "Data_$N_scen.csv"
    CSV.write(joinpath(Data_used_folder,techno_eco),df_techno_eco ; writeheader = false)

    #----------------------------Main results---------------------------

    R_fuelprice = zeros(U) ; R_fuelprice_t = zeros(U) ; R_fixOM = zeros(U) ; R_varOM = zeros(U) ;
    R_invest = zeros(U) ; R_invest_year = zeros(U) ; R_production = zeros(U) ; R_sold = zeros(U);
    R_fuelsold_t = zeros(U) ; R_prodcost = zeros(U) ; R_capacity = zeros(U) ;
    R_El_cons = zeros(U) ; R_costs = zeros(U) ; R_cost_unit = zeros(U) ;
    R_load_av = zeros(U) ; R_FLH = zeros(U) ; R_prodcost_fuel = zeros(U) ;
    R_prodcost_fuel_GJ = zeros(U) ; R_prodcost_fuel_MWh = zeros(U) ;
    R_prodcost_perunit = zeros(U); R_year = Array{String,1}(undef,U) ; R_location = Array{String,1}(undef,U) ;
    R_fuel = Array{String,1}(undef,U) ; R_electrolyser = Array{String,1}(undef,U) ;
    R_CO2_capture = Array{String,1}(undef,U) ; R_profile = Array{String,1}(undef,U) ;
    R_elec_cost = zeros(U) ; R_scenario = Array{String,1}(undef,U);
    if ! isnothing(All_CSP_tech)
      R_CSP_tech = Array{String,1}(undef,U);
    end
    if ! isnothing(All_power_TS)
      R_power_TS = Array{String,1}(undef,U);
    end

    for u=1:nGb
      R_fuelprice_t[Grid_buy[u]] = sum(Price_Profile[Grid_buy_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]]) for t=1:T)*10^-6*Currency_factor
    end

    for u=1:U
        R_scenario[u] = Scenario_name
        R_year[u] = Year
        R_location[u] = Location
        R_profile[u] = Profile_name
        R_fuel[u] = Fuel
        R_electrolyser[u] = Electrolyser
        R_CO2_capture[u] = CO2_capture
        if ! isnothing(All_CSP_tech)
          R_CSP_tech[u] = CSP_tech
        end
        if ! isnothing(All_power_TS)
          R_power_TS[u] = Power_TS
        end
        R_capacity[u] = JuMP.value.(Capacity[u])*10^-3 #In MW for unit producing electricity, in t/h for other units, in t for hydrogen storage, in MWh for batteries
        R_invest[u] = Invest[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor #In M€ (€ is default but currency factor can be applied)
        R_invest_year[u] = R_invest[u]*Annuity_factor[u] #Annulized investment in M€
        R_fixOM[u] = FixOM[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor #In M€
        R_varOM[u] = sum(VarOM[u]* JuMP.value.(X[u,t]) for t in Time)*10^-6*Currency_factor #In M€
        R_fuelprice[u] = sum(Fuel_Buying_fixed[u]*JuMP.value.(Bought[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelprice_t[u] # In M€
        R_production[u] = sum(JuMP.value.(X[u,t]) for t in Time)*10^-6 #In ktons ou GWh (values obtained for storage systems doesn't mean much)
        R_sold[u] = - sum(Fuel_Selling_fixed[u]*JuMP.value.(Sold[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelsold_t[u] #Revenue from by-prduct sale in M€
        R_cost_unit[u] = R_invest_year[u] + R_fixOM[u] + R_varOM[u] + R_fuelprice[u] + R_sold[u]
        R_load_av[u] = sum(JuMP.value.(X[u,t])/JuMP.value.(Capacity[u]) for t in Time)*1/T
        R_FLH[u] = R_load_av[u]*T
        R_El_cons[u] = sum(Sc_nom[u]*JuMP.value.(X[u,t]) for t in Time)*10^-6
        if R_production[u] == 0
          R_prodcost_perunit[u] = 0
        else
          R_prodcost_perunit[u] = R_cost_unit[u]/R_production[u]
        end
    end
    for u in MainFuel
      R_prodcost_fuel[u] = (JuMP.value.(Costs)*10^-6*Currency_factor)/R_production[u]
      R_prodcost_fuel_GJ[u] = R_prodcost_fuel[u]*1000/Fuel_energy_content
      R_prodcost_fuel_MWh[u] = R_prodcost_fuel_GJ[u]*3.6
    end

    R_elec_cost_1 = 10^3*sum(R_prodcost_perunit[u]*R_production[u] for u in PU)/sum(R_production[u] for u in PU)
    for u=1:U
      R_elec_cost[u] = R_elec_cost_1
    end

    if ! isnothing(All_CSP_tech)
      df_results = DataFrame([R_scenario, Name_selected_units, R_year,R_location, R_profile, 
      R_fuel,R_electrolyser,R_CO2_capture, R_CSP_tech, R_capacity, R_invest, R_invest_year, R_fixOM, R_varOM,
      R_fuelprice, R_cost_unit, R_production,R_sold, R_El_cons,
      R_prodcost_fuel, R_prodcost_fuel_GJ, R_prodcost_fuel_MWh,R_prodcost_perunit,
      R_load_av, R_FLH,R_elec_cost], :auto)
      results = "Scenario_$N_scen.csv"
      Result_name = ["Scenario","Type of unit","Year data","Location","Profile","Fuel","Electrolyser",
      "CO2 capture", "CSP technology","Installed capacity (MW (electrical unit), t/h (non electrical), MWh (batteries), t (h2 tank))","Total investment(MEuros)",
      "Annualised investment(MEuros)", "Fixed O&M(MEuros)", "Variable O&M(MEuros)",
      "Fuel cost(MEuros)","Cost per unit(MEuros)","Production(kton or GWh)","Sale (MEuros)",
      "Electricity consumption(GWh)", "Production cost fuel (Euros/kgfuel)",
      "Production cost fuel (Euros/GJfuel)","Production cost fuel (Euros/MWhfuel)",
      "Production cost per unit (Euros/kg or kWh output)", "Load average","Full load hours", "Av electricity cost(Euros/MWh)"]
      rename!(df_results, Result_name)
    elseif ! isnothing(All_power_TS)
      df_results = DataFrame([R_scenario, Name_selected_units, R_year,R_location, R_profile, R_power_TS,
      R_fuel,R_electrolyser,R_CO2_capture, R_capacity, R_invest, R_invest_year, R_fixOM, R_varOM,
      R_fuelprice, R_cost_unit, R_production,R_sold, R_El_cons,
      R_prodcost_fuel, R_prodcost_fuel_GJ, R_prodcost_fuel_MWh,R_prodcost_perunit,
      R_load_av, R_FLH,R_elec_cost], :auto)
      results = "Scenario_$N_scen.csv"
      Result_name = ["Scenario","Type of unit","Year data","Location","Profile","Power time series","Fuel","Electrolyser",
      "CO2 capture", "Installed capacity (MW (electrical unit), t/h (non electrical), MWh (batteries), t (h2 tank))","Total investment(MEuros)",
      "Annualised investment(MEuros)", "Fixed O&M(MEuros)", "Variable O&M(MEuros)",
      "Fuel cost(MEuros)","Cost per unit(MEuros)","Production(kton or GWh)","Sale (MEuros)",
      "Electricity consumption(GWh)", "Production cost fuel (Euros/kgfuel)",
      "Production cost fuel (Euros/GJfuel)","Production cost fuel (Euros/MWhfuel)",
      "Production cost per unit (Euros/kg or kWh output)", "Load average","Full load hours", "Av electricity cost(Euros/MWh)"]
      rename!(df_results, Result_name)
    else
      df_results = DataFrame([R_scenario, Name_selected_units, R_year,R_location, R_profile,
      R_fuel,R_electrolyser,R_CO2_capture, R_capacity, R_invest, R_invest_year, R_fixOM, R_varOM,
      R_fuelprice, R_cost_unit, R_production,R_sold, R_El_cons,
      R_prodcost_fuel, R_prodcost_fuel_GJ, R_prodcost_fuel_MWh,R_prodcost_perunit,
      R_load_av, R_FLH,R_elec_cost], :auto)
      results = "Scenario_$N_scen.csv"
      Result_name = ["Scenario","Type of unit","Year data","Location","Profile","Fuel","Electrolyser",
      "CO2 capture", "Installed capacity (MW (electrical unit), t/h (non electrical), MWh (batteries), t (h2 tank))","Total investment(MEuros)",
      "Annualised investment(MEuros)", "Fixed O&M(MEuros)", "Variable O&M(MEuros)",
      "Fuel cost(MEuros)","Cost per unit(MEuros)","Production(kton or GWh)","Sale (MEuros)",
      "Electricity consumption(GWh)", "Production cost fuel (Euros/kgfuel)",
      "Production cost fuel (Euros/GJfuel)","Production cost fuel (Euros/MWhfuel)",
      "Production cost per unit (Euros/kg or kWh output)", "Load average","Full load hours", "Av electricity cost(Euros/MWh)"]
      rename!(df_results, Result_name)
    end

    CSV.write(joinpath(Main_result_folder,results),df_results)
    CSV.write(joinpath(Main_all_results_folder,results),df_results)
  else
    println("No optimal solution available")
  end

global N_scen += 1 #Increment and run the script for another scenario

end

#Finish time
#elapsed_time = (time_ns() - start_time) * 1e-9 # Convert to seconds