module Solve_LP_2obj

include("../WriteResults/Results_LP.jl")

using .Results_LP
using JuMP, CSV, DataFrames, XLSX, Gurobi, HiGHS

export Solve_OptiPlant_LP_2obj, OptiPlantResultsLP_2obj, generate_adaptive_pareto_curve

struct OptiPlantResultsLP_2obj
    Flows::Matrix{Float64}     
    Sold::Matrix{Float64}     
    Bought::Matrix{Float64}     
    Capacity::Vector{Float64}
    Objectives::Dict{Symbol, Float64}     # all objective values (Costs, Emissions, LandUse, etc.)
    yearly_demand_scaling_factor::Float64
end

function Solve_OptiPlant_LP_2obj(opt_data, solver;
  objective_to_minimize = objective1,
  epsilon_objective::Union{String,Nothing} = nothing,
  Max_value::Union{Float64,Nothing} = nothing)

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
  lcia = opt_data.dat_lcia # Lcia data

  T = scd.T
  Time = scd.Time
  Tstart = scd.Tstart

  #-----------------------------------Model----------------------------------

  #Decision variables
  @variable(Model_LP,X[1:U,t in Time] >= 0) # Products and energy flow (kg/h or kW)
  @variable(Model_LP,Capacity[1:U] >= 0) #  Production capacity of each unit (kg/h or kW)
  @variable(Model_LP,Sold[1:U,t in Time] >= 0) # Quantity of products sold (kg/h or kW)
  @variable(Model_LP,Bought[1:U,t in Time] >= 0) # Quantity of input bought (kg/h or kW)
  for t in Time, u=1:U
    if td.Used_Unit[u]==0
      for var in [X[u, t], Capacity[u], Sold[u, t], Bought[u, t]]
        @constraint(Model_LP, var <= 0)
      end
    end
  end

  #Define the different possibles objectives

  objectives = Dict{Symbol, JuMP.AffExpr}()

  #Costs equation in same currency as input data file (usually EUR2019)
  objectives[:costs] = @expression(Model_LP, sum(td.Fuel_Buying_fixed[u]*Bought[u,t] for u=1:U, t in Time)
  + sum(pd.Price_Profile[sd.Grid_buy_p[u],t]*Bought[sd.Grid_buy[u],Time[t]]*pd.Renewable_criterion_profile[t] for u=1:sd.nGb,t=1:T if sd.Grid_buy_p[u] > 0 && sd.Grid_buy[u] > 0)
  + sum((pd.Price_Profile[sd.Grid_buy_p[u],t]+scd.NonRenCostPenalty)*Bought[sd.Grid_buy[u],Time[t]]*(1-pd.Renewable_criterion_profile[t]) for u=1:sd.nGb,t=1:T if sd.Grid_buy_p[u] > 0 && sd.Grid_buy[u] > 0)
  + sum(pd.Price_Profile[sd.Heat_buy_p[u],t]*Bought[sd.Hourly_heat_buy[u],Time[t]] for u=1:sd.nHb,t=1:T if sd.Heat_buy_p[u] > 0 && sd.Hourly_heat_buy[u] > 0)
  + sum(scd.CO2taxWTTop*pd.Grid_CO2_profile_regulated[t]*Bought[sd.Grid_buy[u],Time[t]] for u=1:sd.nGb, t=1:T if sd.Grid_buy[u] > 0)
  + sum((td.Invest[u]*td.Annuity_factor[u] + td.FixOM[u] + scd.CO2taxWTTup*td.CO2_inf_reg[u])*Capacity[u] for u=1:U)
  + sum((td.VarOM[u] + scd.CO2taxWTTop*td.CO2_proc_fixed_reg[u])*X[u,t] for u=1:U,t in Time)
  - sum(td.Fuel_Selling_fixed[u]*Sold[u,t] for u=1:U,t in Time)
  - sum(pd.Price_Profile[sd.Grid_sell_p[u],t]*Sold[sd.Grid_sell[u],Time[t]] for u=1:sd.nGs,t=1:T if sd.Grid_sell_p[u] > 0 && sd.Grid_sell[u] > 0)
  - sum(pd.Price_Profile[sd.Heat_sell_p[u],t]*Sold[sd.Heat_sell[u],Time[t]] for u=1:sd.nHs,t=1:T if sd.Heat_sell_p[u] > 0 && sd.Heat_sell[u] > 0)
  )

  #"Total" emissions count equation in kg CO2e per year
  objectives[:emissions_CO2e_regulated] = @expression(Model_LP, sum(pd.Grid_CO2_profile_regulated[t]*Bought[sd.Grid_buy[u],Time[t]] for u=1:sd.nGb, t=1:T)
  + sum(td.CO2_inf_reg[u]*Capacity[u] for u=1:U)
  + sum(td.CO2_proc_fixed_reg[u]*X[u,t] for u=1:U,t in Time))

  #Write objectives for all the lca impact categories
  for (cat,impacts) in lcia.scores

    objectives[cat] = @expression(Model_LP,
        sum(impacts.inf[u] * Capacity[u] for u in 1:U) +
        sum(impacts.use[u] * X[u,t] for u in 1:U, t in Time) +
        sum(impacts.disp[u] * Capacity[u] for u=1:U) +
        sum(pd.Lcia_grid_profile[cat][t] * Bought[sd.Grid_buy[u],Time[t]] for u=1:sd.nGb, t=1:T if sd.Grid_buy[u] > 0)
    )
  end

  #Non-negativity constraints for all objectives
  for (obj_name, expr) in objectives
    @constraint(Model_LP, expr >= 0)
  end
  
  # `objective_to_minimize` and `epsilon_objective` are Symbols or Strings
  main_obj_sym = Symbol(objective_to_minimize)

  if !haskey(objectives, main_obj_sym)
    @error("Objective to minimize not found in objectives dictionary: $main_obj_sym")
  end

  if !isnothing(epsilon_objective)
    epsilon_obj_sym = Symbol(epsilon_objective)
    if !haskey(objectives, epsilon_obj_sym)
      @error("Epsilon objective not found in objectives dictionary: $epsilon_obj_sym")
    end
  end

  if isnothing(epsilon_objective)
      # Single-objective minimization
      println("Minimizing ", main_obj_sym)
      @objective(Model_LP, Min, objectives[main_obj_sym])
  else
      # ε-constraint minimization
      epsilon_obj_sym = Symbol(epsilon_objective)
      println("Minimizing ", main_obj_sym, " with ε-constraint on ", epsilon_obj_sym)
      @objective(Model_LP, Min, objectives[main_obj_sym])
      @constraint(Model_LP, objectives[epsilon_obj_sym] <= Max_value)
  end


  #Enforcement of a maximum WTT operational emissions over a year in kg CO2e, Treshold also mean that grid electricity intensity is below x value. 
  if scd.CO2WTTop_treshold >= 0
    @constraint(Model_LP, sum(pd.Grid_CO2_profile_regulated[t]*Bought[sd.Grid_buy[u],Time[t]] for t=1:T if sd.Grid_buy[u] > 0)
    + sum(td.CO2_proc_fixed_reg[u]*X[u,t] for u=1:U,t in Time) <= scd.CO2WTTop_treshold*Fuel_energy_content*sum(Sold[i,t] for t in Time, i in sd.MinD))
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

    #Extract objectives from the dictionary
    Objectives_vals = Dict{Symbol, Float64}()
    for (obj_name, expr) in objectives
      Objectives_vals[obj_name] = JuMP.value(expr) / yearly_demand_scaling_factor
    end

    return OptiPlantResultsLP_2obj(
      X_vals,
      Sold_vals,
      Bought_vals,
      Capacity_vals,
      Objectives_vals,
      yearly_demand_scaling_factor
    )
  else
    println("No optimal solution available")
        return OptiPlantResultsLP_2obj(
        zeros(size(X)),
        zeros(size(Sold)),
        zeros(size(Bought)),
        zeros(U),
        Dict{Symbol, Float64}(),  # empty objectives
        0.0
    )
  end

end

function generate_adaptive_pareto_curve(opt_data, solver, N_scen, resultsfolder,
                                        results_currency, results_currency_multiplier,
                                        default_results_cost_scale,
                                        default_results_capacity_units,
                                        default_results_production_units,
                                        remove_lcia_phases,
                                        N_pareto_points,
                                        interior_points,
                                        objective1,
                                        objective2)

    # Define Pareto results folder

    pareto_results_folder = joinpath(resultsfolder, opt_data.dat_scen.Result_folder_name,"$objective1 vs $objective2")
    if !isdir(pareto_results_folder)
      mkpath(pareto_results_folder)
    end
    
    # Initialize Pareto fronts with dynamic column names
    pareto_front = DataFrame(Solution_number=Int[])
    pareto_front[!, objective1] = Float64[]
    pareto_front[!, objective2] = Float64[]

    pareto_front_scaled = DataFrame(Solution_number=Int[])
    pareto_front_scaled[!, objective1] = Float64[]
    pareto_front_scaled[!, objective2] = Float64[]

    # --- Helper to add solution ---
    function add_solution!(df, df_scaled, sol_id, opt_result)
        val1 = opt_result.Objectives[Symbol(objective1)]
        val2 = opt_result.Objectives[Symbol(objective2)]
        val1_scaled = val1 * opt_result.yearly_demand_scaling_factor
        val2_scaled = val2 * opt_result.yearly_demand_scaling_factor
        push!(df, (sol_id, val1, val2))
        push!(df_scaled, (sol_id, val1_scaled, val2_scaled))
    end

    # --- Step 1: Extreme points ---
    # Minimize objective 1
    opt_obj1 = Solve_OptiPlant_LP_2obj(opt_data, solver;
                                       objective_to_minimize=objective1)
    add_solution!(pareto_front, pareto_front_scaled, 1, opt_obj1)
    write_main_results_LP(opt_data, opt_obj1, N_scen, resultsfolder,
                          results_currency, results_currency_multiplier,
                          default_results_cost_scale, default_results_capacity_units,
                          default_results_production_units, remove_lcia_phases;
                          model="LP_2obj", pareto_results_folder = pareto_results_folder, Sol_number=1)

    # Minimize objective 2
    opt_obj2 = Solve_OptiPlant_LP_2obj(opt_data, solver;
                                       objective_to_minimize=objective2)
    add_solution!(pareto_front, pareto_front_scaled, N_pareto_points, opt_obj2)
    write_main_results_LP(opt_data, opt_obj2, N_scen, resultsfolder,
                          results_currency, results_currency_multiplier,
                          default_results_cost_scale, default_results_capacity_units,
                          default_results_production_units, remove_lcia_phases;
                          model="LP_2obj", pareto_results_folder = pareto_results_folder, Sol_number=N_pareto_points)

    sol_id = 1

    # --- Step 2: Iterative refinement ---
    while nrow(pareto_front) < N_pareto_points
        sort!(pareto_front_scaled, objective2, rev=true)

        variations = [abs(pareto_front_scaled[i, objective1] - pareto_front_scaled[i+1, objective1])
                      for i in 1:(nrow(pareto_front_scaled)-1)]
        isempty(variations) && break

        idx_max_var = argmax(variations)
        obj2_high = pareto_front_scaled[idx_max_var, objective2]
        obj2_low  = pareto_front_scaled[idx_max_var+1, objective2]

        n_intervals = interior_points + 1
        step = (obj2_high - obj2_low) / n_intervals
        epsilon_values = [obj2_high - i * step for i in 1:interior_points]

        for e in epsilon_values
            sol_id += 1
            if sol_id >= N_pareto_points
                break
            end

            # Generic call to solver with epsilon-constraint
            opt_results = Solve_OptiPlant_LP_2obj(opt_data, solver;
                                                  objective_to_minimize=objective1,
                                                  epsilon_objective=objective2,
                                                  Max_value=e)

            add_solution!(pareto_front, pareto_front_scaled, sol_id, opt_results)

            write_main_results_LP(opt_data, opt_results, N_scen, resultsfolder,
                                  results_currency, results_currency_multiplier,
                                  default_results_cost_scale, default_results_capacity_units,
                                  default_results_production_units, remove_lcia_phases;
                                  model="LP_2obj", pareto_results_folder = pareto_results_folder, Sol_number=sol_id)
        end
    end

    # Final sort by objective2 (secondary axis)
    sort!(pareto_front, objective2, rev=true)
    sort!(pareto_front_scaled, objective2, rev=true)

    CSV.write(joinpath(pareto_results_folder,"pareto_scen_$N_scen.csv"), pareto_front)
    CSV.write(joinpath(pareto_results_folder,"pareto_scaled_scen_$N_scen.csv"), pareto_front_scaled)

    return "Successful execution, pareto results available in $pareto_results_folder"
end

end # Module end

#=
function order_of_magnitude(x::Real)
  x == 0 && return 0  # convention: order of magnitude of 0 is 0
  exp = floor(Int, log10(abs(x)))
  return 10.0 ^ exp
end

#scaling_factor_2nd_obj = order_of_magnitude(MinCosts_scaled) / order_of_magnitude(MinCO2_scaled)
=#