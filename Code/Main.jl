using Pkg

#------------------------------Problem set up------------------------------------
#Project name
Project = "Base"
# Folder name for all csv file
all_csv_files = "All_results"
# Folder paths for data acquisition and writing
Main_folder = "C:/Users/njbca/Documents/Models/OptiPlantGitHub" ; 
#cd(joinpath(Main_folder,"envgit")) ; Pkg.activate(pwd()) ; #Activate the environment from the folder
cd(joinpath(Main_folder,"Code")) ; #Go back to the code folder
using JuMP, Gurobi, CSV, DataFrames ; #Use necessary packages

Profile_folder = joinpath(Main_folder,Project,"Data","Profiles") ; #mkpath(Profile_folder)
Inputs_folder = joinpath(Main_folder,Project,"Data","Inputs") ; #mkpath(Techno_economics_folder)
Inputs_file = "All_data"

# Scenario set (same name as exceel sheet)
Scenarios_set = "Scenarios" ; include("ImportScenarios.jl")
# Scenario under study (all between N_scen_0 and N_scen_end)
N_scen_0 = 1 ; N_scen_end = 1 # or N_scen_end = N_scenarios for total number of scenarios
#Studied hours (max 8760). When there is maintenance hours are out
#TMend = 4000-4876 : 90% time working ; T = 4000-4761 : 8000 hours
TMstart = 4000 ; TMend = 4876 ; Tbegin = 72 ; Tfinish=8760 #Time maintenance starts/end ; Time within plants can operate at 0% load (in case of no renewable power the first 3 days)
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
  Sold_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Sold") ; mkpath(Sold_result_folder)
  Bought_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Hourly results","Bought") ; mkpath(Bought_result_folder)
  Main_result_folder = joinpath(Main_folder,Project,"Results",csv_files,"Main results") ; mkpath(Main_result_folder)
  Main_all_results_folder = joinpath(Main_folder,Project,"Results",all_csv_files,"Main results") ; mkpath(Main_all_results_folder)
  Data_used_folder = joinpath(Main_folder,Project,"Results",csv_files,"Data used") ; mkpath(Data_used_folder)
  #-----------------------------------Model----------------------------------
  Model_LP_PW = Model(Gurobi.Optimizer)
  #Model_LP_PW = Model(GLPK.Optimizer)

  #Decision variables
  @variable(Model_LP_PW,X[1:U,t in Time] >= 0) # Products and energy flow (kg/h or kW)
  @variable(Model_LP_PW,Capacity[1:U] >=0) #  Production capacity of each unit (kg/h or kW)
  @variable(Model_LP_PW,Sold[1:U,t in Time] >= 0) # Quantity of products sold (kg/h or kW)
  @variable(Model_LP_PW,Bought[1:U,t in Time] >= 0) # Quantity of input bought (kg/h or kW)


  # Set higher bound to 0 for not used units
  for t in Time, u=1:U
    if Used_Unit[u]==0
      @constraint(Model_LP_PW,X[u,t] <= 0)
      @constraint(Model_LP_PW,Capacity[u] <= 0)
      @constraint(Model_LP_PW,Sold[u,t] <= 0)
      @constraint(Model_LP_PW,Bought[u,t] <= 0)
    end
  end

  #Objective function (cost minimization)

 #Minimize the total cost of the system
    @objective(Model_LP_PW, Min,
    sum(Fuel_Buying_fixed[u]*Bought[u,t] for u=1:U, t in Time)
    + sum(Price_Profile[Grid_buy_p[u],t]*Bought[Grid_buy[u],Time[t]] for u=1:nGb,t=1:T)
    + sum((Invest[u]*Annuity_factor[u] + FixOM[u])*Capacity[u] for u=1:U)
    + sum(VarOM[u] * X[u,t] for u=1:U,t in Time)
    - sum(Fuel_Selling_fixed[u]*Sold[u,t] for u=1:U,t in Time)
    )
#Constraints
  #Yearly demand: have to fullfill min yearly demand if there is one
  @constraint(Model_LP_PW,[i in MinD], sum(Sold[i,t] for t in Time) == Demand[i])

  #Load constraints:

  @constraint(Model_LP_PW,[u=1:U,t in Tstart], X[u,t] >= Capacity[u]*Load_min[u]) #Min flow
  @constraint(Model_LP_PW,[u=1:U,t in Time], X[u,t] <= Capacity[u]*Load_max[u]) #Max flow

  #Ramping constraints
  if Option_ramping == true

    @constraint(Model_LP_PW,[u=1:U,t=1:T], X[u,Time[t]]-(t>Time[1] ? X[u,Time[t-1]] : 0) <= Ramp_up[u]*Capacity[u])
    @constraint(Model_LP_PW,[u=1:U,t=1:T], (t>Time[1] ? X[u,Time[t-1]] : 0)-X[u,Time[t]] <= Ramp_down[u]*Capacity[u])

  end

  # Productions rates

  @constraint(Model_LP_PW,[i=1:nProd,t in Time], X[Products[i],t] == X[Reactants[i],t]*Prod_rate[Products[i]])
  # Hydrogen balance
  @constraint(Model_LP_PW,[t in Time],sum(H2_balance[u]*X[u,t] for u=1:U)==0)
  # Heat balance
  @constraint(Model_LP_PW,[t in Time],sum(Heat_balance[u]*Heat_generated[u]*X[u,t] for u=1:U)==0)
  # Storages balance
  @constraint(Model_LP_PW,[i=1:nST,t=1:T], X[Tanks[i],Time[t]] == (t>Time[1] ? X[Tanks[i],Time[t-1]] : 0) + X[Stor_in[i],Time[t]] - X[Stor_out[i],Time[t]])

  # Renewable energy production constraint (profile dependent)
  @constraint(Model_LP_PW, [i = 1:nRPU,t=1:T], X[RPU[i],Time[t]] == Flux_Profile[RPU_p[i],t]*Capacity[RPU[i]])

  # Electricity produced and consumed have to be at equilibrium
  @constraint(Model_LP_PW, [t in Time], sum(El_balance[u]*X[u,t] for u=1:U) ==
  sum(Sc_nom[u]*X[u,t] for u=1:U))

  # Sold and bought ouputs/inputs
  @constraint(Model_LP_PW,[u=1:U,t in Time],Sold[u,t] <= X[u,t]) # Have to sell less than what is produced
  @constraint(Model_LP_PW,[u=1:U,t in Time],Bought[u,t] == X[u,t]) # Have to buy exactly what you use

  # solve
  optimize!(Model_LP_PW)

  #--------------------------Results output------------------------------------------
  if termination_status(Model_LP_PW) == MOI.OPTIMAL
    Optimum = objective_value(Model_LP_PW)

    #----------------Variable flows and total specific consumption -------------
    Infos = Array{String,1}(undef,T)
    Infos[1] = "Scenario: "*Scenario_name
    Infos[2] = "Year: "*"$Year"
    Infos[3] = "Location: "*Location
    Infos[4] = "Fuel: "*Fuel
    Infos[5] = "Electrolyser: "*Electrolyser

    for i=6:T
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

    #-----------------------Techno_economical data used------------------------

    df_techno_eco = DataFrame(Data_units[Parameters_index[1]:end,Subsets_index[2]:end],:auto)
    techno_eco = "Data_$N_scen.csv"
    CSV.write(joinpath(Data_used_folder,techno_eco),df_techno_eco ; writeheader = false)

    #----------------------------Main results---------------------------

    R_fuelprice = zeros(U) ; R_fuelprice_t = zeros(U) ; R_fixOM = zeros(U) ; R_varOM = zeros(U) ;
    R_invest = zeros(U) ; R_invest_year = zeros(U) ; R_production = zeros(U) ;
    R_sold = zeros(U); R_fuelsold_t = zeros(U) ; R_prodcost = zeros(U) ; R_capacity = zeros(U) ;
    R_El_cons = zeros(U) ; R_optimum = zeros(U) ; R_cost_unit = zeros(U) ; R_load_av = zeros(U) ;
    R_FLH = zeros(U) ; R_prodcost_syst = zeros(U) ; R_prodcost_unit = zeros(U); R_year = zeros(U) ;
    R_location = Array{String,1}(undef,U) ; R_fuel = Array{String,1}(undef,U) ; R_electrolyser = Array{String,1}(undef,U) ;
    R_elec_cost = zeros(U) ; Scenario = Array{String,1}(undef,U);
    for u=1:nGb
      R_fuelprice_t[Grid_buy[u]] = sum(Price_Profile[Grid_buy_p[u],t]*JuMP.value.(Bought[Grid_buy[u],Time[t]]) for t=1:T)*10^-6*Currency_factor
    end
    for u=1:U
        Scenario[u] = Scenario_name
        R_year[u] = Year
        R_location[u] = Location
        R_fuel[u] = Fuel
        R_electrolyser[u] = Electrolyser
        R_capacity[u] = JuMP.value.(Capacity[u])*10^-3
        R_invest[u] = Invest[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor
        R_invest_year[u] = R_invest[u]*Annuity_factor[u]
        R_fixOM[u] = FixOM[u]*JuMP.value.(Capacity[u])*10^-6*Currency_factor
        R_varOM[u] = sum(VarOM[u] * JuMP.value.(X[u,t]) for t in Time)*10^-6*Currency_factor
        R_fuelprice[u] = sum(Fuel_Buying_fixed[u]*JuMP.value.(Bought[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelprice_t[u]
        R_production[u] = sum(JuMP.value.(X[u,t]) for t in Time)*10^-6
        R_sold[u] = - sum(Fuel_Selling_fixed[u]*JuMP.value.(Sold[u,t]) for t in Time)*10^-6*Currency_factor + R_fuelsold_t[u]
        R_cost_unit[u] = R_invest_year[u] + R_fixOM[u] + R_varOM[u] + R_fuelprice[u] + R_sold[u]
        R_load_av[u] = sum(JuMP.value.(X[u,t])/JuMP.value.(Capacity[u]) for t in Time)*1/T
        R_FLH[u] = R_load_av[u]*T
        R_El_cons[u] = sum(Sc_nom[u]*JuMP.value.(X[u,t]) for t in Time)*10^-6
        if R_production[u] == 0
          R_prodcost_syst[u] = 0 ; R_prodcost_unit[u] = 0
        else
          R_prodcost_syst[u] = (Optimum*10^-6*Currency_factor)/R_production[u]
          R_prodcost_unit[u] = R_cost_unit[u]/R_production[u]
        end
    end

    R_elec_cost_1 = 10^3*sum(R_prodcost_unit[u]*R_production[u] for u in GPU)/sum(R_production[u] for u in GPU)
    for u=1:U
      R_elec_cost[u] = R_elec_cost_1
    end

    df_results = DataFrame([Scenario, Name_selected_units, R_year,R_location,
    R_fuel,R_electrolyser, R_capacity, R_invest,
    R_invest_year, R_fixOM, R_varOM, R_fuelprice,R_cost_unit, R_production,
    R_sold, R_El_cons, R_prodcost_syst, R_prodcost_unit, R_load_av, R_FLH, R_elec_cost],:auto)
    results = "Scenario_$N_scen.csv"
    Result_name = ["Scenario","Type of unit","Year","Location","Fuel","Electrolyser",
    "Installed capacity(MW or t/h)","Total investment(MEuros)",
    "Annualised investment(MEuros)", "Fixed O&M(MEuros)", "Variable O&M(MEuros)",
    "Fuel cost(MEuros)","Cost per unit(MEuros)","Production(kton or GWh)","Sale (MEuros)",
    "Electricity consumption(GWh)", "Production cost per output with total costs (Euros/kg or kWh)",
    "Production cost per output with unit costs (Euros/kg or kWh)", "Load average","Full load hours","Av electricity cost(Euros/MWh)"]
    rename!(df_results, Result_name)
    CSV.write(joinpath(Main_result_folder,results),df_results)
    CSV.write(joinpath(Main_all_results_folder,results),df_results)
  else
    println("No optimal solution available")
  end

global N_scen += 1 #Increment and run the script for another scenario

end
