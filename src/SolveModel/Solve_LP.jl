module Solve_LP

using JuMP, CSV, DataFrames, XLSX, Gurobi, HiGHS

export Solve_OptiPlant_LP, OptiPlantResultsLP

struct OptiPlantResultsLP
    Flows::Matrix{Float64}     
    Sold::Matrix{Float64}     
    Bought::Matrix{Float64}     
    Capacity::Vector{Float64}
    Costs::Float64
end

function Solve_OptiPlant_LP(opt_data, solver)

  if solver == "Gurobi"
      Model_LP = Model(Gurobi.Optimizer)
  else
      Model_LP = Model(HiGHS.Optimizer)
  end
  
  #Unpack some of the optimization data
  U = opt_data.U
  td = opt_data.dat_t #Techno-economic data
  sd = opt_data.dat_sub #Subset data
  pd = opt_data.dat_p #Profile data
  scd = opt_data.dat_scen #Scenario data

  T = scd.T
  Time = scd.Time
  Tstart = scd.Tstart

  #-----------------------------------Model----------------------------------

  #Decision variables
  @variable(Model_LP,Costs) # In € (or other currency)
  @variable(Model_LP,X[1:U,t in Time] >= 0) # Products and energy flow (kg/h or kW)
  @variable(Model_LP,Capacity[1:U] >=0) #  Production capacity of each unit (kg/h or kW)
  @variable(Model_LP,Sold[1:U,t in Time] >= 0) # Quantity of products sold (kg/h or kW)
  @variable(Model_LP,Bought[1:U,t in Time] >= 0) # Quantity of input bought (kg/h or kW)
  for t in Time, u=1:U
    if td.Used_Unit[u]==0
      for var in [X[u, t], Capacity[u], Sold[u, t], Bought[u, t]]
        @constraint(Model_LP, var <= 0)
      end
    end
  end

  #Minimize the total cost of the system 
  
  @objective(Model_LP, Min, Costs)

   #Costs equation in same currency as input data file (usually €2019)
  @constraint(Model_LP, Costs == sum(td.Fuel_Buying_fixed[u]*Bought[u,t] for u=1:U, t in Time)
  + sum(pd.Price_Profile[sd.Grid_buy_p[u],t]*Bought[sd.Grid_buy[u],Time[t]]*pd.Renewable_criterion_profile[t] for u=1:sd.nGb,t=1:T if sd.Grid_buy_p[u] > 0 && sd.Grid_buy[u] > 0)
  + sum((pd.Price_Profile[sd.Grid_buy_p[u],t]+scd.NonRenCostPenalty)*Bought[sd.Grid_buy[u],Time[t]]*(1-pd.Renewable_criterion_profile[t]) for u=1:sd.nGb,t=1:T if sd.Grid_buy_p[u] > 0 && sd.Grid_buy[u] > 0)
  + sum(pd.Price_Profile[sd.Heat_buy_p[u],t]*Bought[sd.Hourly_heat_buy[u],Time[t]] for u=1:sd.nHb,t=1:T if sd.Heat_buy_p[u] > 0 && sd.Hourly_heat_buy[u] > 0)
  + sum(scd.CO2taxWTTop*pd.CO2_profile_regulated[sd.Grid_CO2_regulated_p[u],t]*Bought[sd.Grid_buy[u],Time[t]] for u=1:sd.nGCO2reg,t=1:T if sd.Grid_CO2_regulated_p[u] > 0 && sd.Grid_buy[u] > 0)
  + sum((td.Invest[u]*td.Annuity_factor[u] + td.FixOM[u] + scd.CO2taxWTTup*td.CO2_inf_reg[u])*Capacity[u] for u=1:U)
  + sum((td.VarOM[u] + scd.CO2taxWTTop*td.CO2_proc_fixed_reg[u])*X[u,t] for u=1:U,t in Time)
  - sum(td.Fuel_Selling_fixed[u]*Sold[u,t] for u=1:U,t in Time)
  - sum(pd.Price_Profile[sd.Grid_sell_p[u],t]*Sold[sd.Grid_sell[u],Time[t]] for u=1:sd.nGs,t=1:T if sd.Grid_sell_p[u] > 0 && sd.Grid_sell[u] > 0)
  - sum(pd.Price_Profile[sd.Heat_sell_p[u],t]*Sold[sd.Heat_sell[u],Time[t]] for u=1:sd.nHs,t=1:T if sd.Heat_sell_p[u] > 0 && sd.Heat_sell[u] > 0)
  )

  #Enforcement of a maximum WTT operational emissions over a year in kg CO2e, Treshold also mean that grid electricity intensity is below x value. 
  if scd.CO2WTTop_treshhold >= 0
    @constraint(Model_LP, sum(pd.CO2_profile_regulated[sd.Grid_CO2_regulated_p[u],t]*Bought[sd.Grid_buy[u],Time[t]] for u=1:sd.nGCO2reg,t=1:T if sd.Grid_CO2_regulated_p[u] > 0)
    + sum(td.CO2_proc_fixed_reg[u]*X[u,t] for u=1:U,t in Time) <= scd.CO2WTTop_treshhold*Fuel_energy_content*sum(Sold[i,t] for t in Time, i in sd.MinD))
  end

  #Enforcement of renewable criterion satisfied at all time
  #--> Can't never take from the grid when renewable criterion is 0 (i.e. considered as non renewable)

  if scd.Criterion_application == -1
    @constraint(Model_LP,[u=1:sd.nGb, t=1:T], Bought[sd.Grid_buy[u],Time[t]] <= pd.Renewable_criterion_profile[t]*X[sd.Grid_buy[u],Time[t]])
  end

  #Demand constraint

  if scd.periodic_demand_targets == true
    Demand_targets = zeros(1,Numbers_of_period)
    for i = 1:1, p =1:Numbers_of_period
      Demand_targets[i,p] = td.Demand[sd.MinD[i]]/Numbers_of_period
    end
    @constraint(Model_LP,[i=1:sd.nMinD, p=1:Numbers_of_period], sum(Sold[sd.MinD[i],t] for t in T_period[p] ) == Demand_targets[i,p])
  else
    yearly_demand_scaling_factor = 10^(-floor(log10(td.Demand[sd.MainFuel[1]])))
    @constraint(Model_LP,[i in sd.MinD], sum(Sold[i,t] for t in Time) == td.Demand[i]*yearly_demand_scaling_factor)
    #@constraint(Model_LP,[i in sd.MinD], sum(Sold[i,t] for t in Time) == td.Demand[i])
  end

  if scd.Option_connection_limit == true
    #Hourly electricity/heat available: can't get electricity/heat from the grid when there is no excess production
    @constraint(Model_LP,[i=1:sd.nGe,t=1:T], X[sd.Grid_in[i],Time[t]] <= pd.Flux_Profile[sd.Grid_excess[i],t])
    @constraint(Model_LP,[i=1:sd.nHe,t=1:T], X[sd.Heat_in[i],Time[t]] <= pd.Flux_Profile[sd.Heat_excess[i],t])
    #Can't export electricity/heat to the grid when there is no external electricity/heat demand
    @constraint(Model_LP,[i=1:sd.nGd, t=1:T],X[sd.Grid_out[i],Time[t]] <= pd.Flux_Profile[sd.Grid_deficit[i],t])
    @constraint(Model_LP,[i=1:sd.nHd, t=1:T],X[sd.Heat_out[i],Time[t]] <= pd.Flux_Profile[sd.Heat_deficit[i],t])
  end

  #Capacity constraints

  if scd.Option_max_capacity == true
    @constraint(Model_LP,[u=1:U], Capacity[u] <= td.Max_Cap[u]) #Maximal capacity that can be installed
    #@constraint(Model_LP,[i=1:sd.nGe], Capacity[sd.Grid_in[i]] <= 30000)  #Maximal grid capacity that can be installed
  end
  
  @constraint(Model_LP,[u=1:U,t in Tstart], X[u,t] >= Capacity[u]*td.Load_min[u]) #Min flow
  @constraint(Model_LP,[u=1:U,t in Time], X[u,t] <= Capacity[u]) #Max flow

  #Ramping constraints
  if scd.Option_ramping == true
    @constraint(Model_LP,[u=1:U,t=1:T], X[u,Time[t]]-(t>Time[1] ? X[u,Time[t-1]] : 0) <= td.Ramp_up[u]*Capacity[u])
    @constraint(Model_LP,[u=1:U,t=1:T], (t>Time[1] ? X[u,Time[t-1]] : 0)-X[u,Time[t]] <= td.Ramp_down[u]*Capacity[u])
  end

  # Productions rates
  @constraint(Model_LP,[i=1:sd.nProd,t in Time], X[sd.Products[i],t] == X[sd.Reactants[i],t]*td.Prod_rate[sd.Products[i]])
  # Hydrogen balance
  @constraint(Model_LP,[t in Time],sum(td.H2_balance[u]*X[u,t] for u=1:U)==0)
  # CSP balance
  @constraint(Model_LP,[t in Time], sum(td.CSP_balance[u]*X[u,t] for u=1:U)==0)
  # District heat balance
  @constraint(Model_LP,[t in Time],sum(td.Heat_balance[u]*td.Heat_generated[u]*X[u,t] for u=1:U)==0)
  # Process heat balance
  @constraint(Model_LP,[t in Time],sum(td.Process_heat_balance[u]*td.Process_heat_generated[u]*X[u,t] for u=1:U)==0)
  # Storages balance
  @constraint(Model_LP,[i=1:sd.nST,t=1:T], X[sd.Tanks[i],Time[t]] == (t>Time[1] ? X[sd.Tanks[i],Time[t-1]] : 0) + X[sd.Stor_in[i],Time[t]] - X[sd.Stor_out[i],Time[t]])
  # Renewable energy production constraint (profile dependent)
  @constraint(Model_LP, [i = 1:sd.nRPU,t=1:T], X[sd.RPU[i],Time[t]] == pd.Flux_Profile[sd.RPU_p[i],t]*Capacity[sd.RPU[i]])
  # Electricity produced and consumed have to be at equilibrium (Production = Consumption)
  @constraint(Model_LP, [t in Time], sum(td.El_balance[u]*X[u,t] for u=1:U) == sum(td.Sc_nom[u]*X[u,t] for u=1:U))
  
  # Sold and bought ouputs/inputs
  @constraint(Model_LP,[u=1:U,t in Time],Sold[u,t] <= X[u,t]) # Have to sell less than what is produced
  @constraint(Model_LP,[u=1:U,t in Time],Bought[u,t] == X[u,t]) # Have to buy exactly what you use

  # Solve
  optimize!(Model_LP)

  # Return results

  if termination_status(Model_LP) == MOI.OPTIMAL
    X_vals = JuMP.value.(X)/yearly_demand_scaling_factor
    Sold_vals = JuMP.value.(Sold)/yearly_demand_scaling_factor
    Bought_vals = JuMP.value.(Bought)/yearly_demand_scaling_factor
    Capacity_vals = JuMP.value.(Capacity)/yearly_demand_scaling_factor
    Costs_vals = JuMP.value.(Costs)/yearly_demand_scaling_factor

    return OptiPlantResultsLP(X_vals, Sold_vals, Bought_vals, Capacity_vals, Costs_vals)
  else
    println("No optimal solution available")
    return OptiPlantResultsLP(zeros(size(X)), zeros(size(Sold)), zeros(size(Bought)),zeros(U),0)
  end

end

end # Module end