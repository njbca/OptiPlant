module Results_LP

include("../ReadData/user_defined/Fuel_energy_content.jl")
include("HelperFunctionsWrite.jl")

using CSV, DataFrames, XLSX

export write_hourly_results_LP, write_main_results_LP

function write_hourly_results_LP(opt_data, opt_results, N_scen, resultsfolder, currency_multiplier)
  
  #Unpack some of the optimization data
  U = opt_data.U
  Name_selected_units = [string(x) for x in opt_data.Name_selected_units] #Extract and convert into a vector of strings
  td = opt_data.dat_t #Techno-economic data
  sd = opt_data.dat_sub #Subset data
  pd = opt_data.dat_p #Profile data
  scd = opt_data.dat_scen #Scenario data

  X = opt_results.Flows
  Sold = opt_results.Sold
  Bought = opt_results.Bought

  T = scd.T
  Time = scd.Time

  # Vector with main scenarios informations
  Infos = Array{String,1}(undef,T)
  Infos[1] = "Scenario: "*scd.Scenario_name
  Infos[2] = "Year data: "*scd.Year
  Infos[3] = "Profile: "*scd.Profile_name
  Infos[4] = "Power time series name: "*scd.Power_TS
  Infos[5] = "Location: "*scd.Location
  Infos[6] = "Fuel: "*scd.Fuel
  Infos[7] = "Electrolyser: "*scd.Electrolyser
  Infos[8] = "CO2 capture: "*scd.CO2_capture
  Infos[9] = "CO2taxWTTup: "*"$(scd.CO2taxWTTup)"
  Infos[10] = "CO2taxWTTop: "*"$(scd.CO2taxWTTop)"
  Infos[11] = "CO2WTTop_treshhold: "*"$(scd.CO2WTTop_treshhold)"
  Infos[12] = "Renewable criterion: "*scd.Current_rencrit
  Infos[13] = "Renewable application: "*"$(scd.Criterion_application)"
  Infos[14] = "CSP tech: "*scd.CSP_tech

  for i = 15:T
      Infos[i] = " "
  end
  
  #---------------- Optimal variable flows and total specific consumption -------------
  if scd.Write_flows == true

    #Check if the folder were to write data exists, create if it does not
    flows_result_folder = joinpath(resultsfolder,scd.Result_folder_name,"Hourly results","Flows")
    if !isdir(flows_result_folder)
      mkpath(flows_result_folder)
    end

    #Total electricity consumption
    Sc_tot = zeros(T)
    for t = 1:T
      Sc_tot[t] = sum(td.Sc_nom[u] * X[u, t] for u=1:U)
    end

    # Flows
    Solution_X = zeros(T, U)
    for u = 1:U, t = 1:T
        Solution_X[t, u] = X[u, t]
    end

    #Counted grid "real" emissions (emissions not affected by regulations and taxes)
    Grid_real_emissions = zeros(T, 1)
    if sd.Grid_CO2_emitted_p != 0
      for t = 1:T
        Grid_real_emissions[t, 1] = pd.CO2_profile_emitted[sd.Grid_CO2_emitted_p[1], t] * Bought[sd.Grid_buy[1], t]
      end
    end

    #Counted grid "legal" emissions (emissions affected by regulations and taxes)
    Grid_legal_emissions = zeros(T, 1)
    if sd.Grid_CO2_regulated_p != 0
      for t = 1:T
        Grid_legal_emissions[t, 1] = pd.CO2_profile_regulated[sd.Grid_CO2_regulated_p[1], t] * Bought[sd.Grid_buy[1], t]
      end
    end

    df_flow = DataFrame(
        [Infos Time Solution_X Sc_tot pd.Renewable_criterion_profile Grid_legal_emissions Grid_real_emissions],
        :auto
    )

    if !isnothing(td.Output_units)
      rename!(
        df_flow,
        ["Informations"; "Time"; Name_selected_units .* " [" .* td.Output_units .* "]"; "Electricity consumption [kWhe]"; 
          "Certified grid electricity (1=true)"; "Legal grid emissions"; 
          "Real grid emissions"]
          )
    else
      rename!(
        df_flow,
        ["Informations"; "Time"; Name_selected_units ; "Electricity consumption [kWhe]"; 
          "Certified grid electricity (1=true)"; "Legal grid emissions"; 
          "Real grid emissions"]
          )
    end
    flows = "F_$N_scen.csv"
    CSV.write(joinpath(flows_result_folder, flows), df_flow)

  end

  #---------------- Variable sold ---------------------------------
  if scd.Write_sold_products == true

    #Check if the folder were to write data exists, create if it does not
    sold_result_folder = joinpath(resultsfolder,scd.Result_folder_name,"Hourly results","Sold")
    if !isdir(sold_result_folder)
      mkpath(sold_result_folder)
    end

    Solution_Sold = zeros(T,U)
    for u=1:U, t=1:T
      Solution_Sold[t,u] = Sold[u,t]
    end
    #Data frame definition
    df_sold = DataFrame([Infos Time Solution_Sold], :auto)
    #Headlines
    if !isnothing(td.Output_units)
      rename!(df_sold, ["Informations";"Time";Name_selected_units .* " [" .* td.Output_units .* "]"])
    else
      rename!(df_sold, ["Informations";"Time";Name_selected_units])
    end
    #File name
    sold = "S_$N_scen.csv"
    #Write the Csv file
    CSV.write(joinpath(sold_result_folder,sold),df_sold)
  end

  #----------------Variable fuel cost (~ bought)---------------------------------
  if scd.Write_fuel_cost == true

    bought_result_folder = joinpath(resultsfolder,scd.Result_folder_name,"Hourly results","Bought")
    if !isdir(bought_result_folder)
      mkpath(bought_result_folder)
    end

    #Data frame definition
    Fuel_cost= zeros(U,T)
    Fuel_cost_t_ren = zeros(U,T)
    Fuel_cost_t_noren = zeros(U,T)
    Solution_Bought = zeros(T,U)
    for u=1:U, t=1:T
      Solution_Bought[t,u] = Bought[u,t]
    end
  
    for u=1:sd.nGb, t=1:T
      Fuel_cost_t_ren[sd.Grid_buy[u],t] = pd.Price_Profile[sd.Grid_buy_p[u],t]*Bought[sd.Grid_buy[u],t]*pd.Renewable_criterion_profile[t]*currency_multiplier #Price of certified electricity
      Fuel_cost_t_noren[sd.Grid_buy[u],t] = (pd.Price_Profile[sd.Grid_buy_p[u],t]+scd.NonRenCostPenalty)*Bought[sd.Grid_buy[u],t]*(1-pd.Renewable_criterion_profile[t])*currency_multiplier #Price of non-certified electricity
    end
    for u=1:sd.nHb, t=1:T
      Fuel_cost_t_ren[sd.Hourly_heat_buy[u],t] = pd.Price_Profile[sd.Heat_buy_p[u],t]*Bought[sd.Hourly_heat_buy[u],t]*currency_multiplier
    end
    for u=1:U, t=1:T
      Fuel_cost[u,t] = Fuel_cost_t_ren[u,t] + Fuel_cost_t_noren[u,t] + td.Fuel_Buying_fixed[u]*Bought[u,t]*currency_multiplier
    end
    df_fuel_cost = DataFrame([Infos Time transpose(Fuel_cost_t_ren) transpose(Fuel_cost_t_noren) transpose(Fuel_cost) Solution_Bought], :auto)
    #Headlines
    if !isnothing(td.Output_units)
      rename!(
        df_fuel_cost,
        ["Informations";"Time"; Name_selected_units.*"_Ren".* " [" .* td.Output_units .* "]";
        Name_selected_units.*"_NotRen".* " [" .* td.Output_units .* "]";
        Name_selected_units.*"_total".* " [" .* td.Output_units .* "]";
        Name_selected_units.*"_Bought".* " [" .* td.Output_units .* "]"]
        )
    else
      rename!(
        df_fuel_cost,
        ["Informations";"Time"; Name_selected_units.*"_Ren";
        Name_selected_units.*"_NotRen";
        Name_selected_units.*"_total";
        Name_selected_units.*"_Bought"]
        )
    end
    #File name
    fuel_cost = "B_$N_scen.csv"
    #Write the Csv file
    CSV.write(joinpath(bought_result_folder,fuel_cost),df_fuel_cost)
  end

end

function write_main_results_LP(opt_data, opt_results, N_scen, resultsfolder,
   results_currency, results_currency_multiplier,
   default_results_cost_scale, default_results_capacity_units, default_results_production_units;
   model::String ="LP", pareto_results_folder::Union{String,Nothing} = nothing,  Sol_number::Int64= 1,
   write_lca_results::Bool = true, remove_lcia_phases::Vector{Symbol} = Symbol[:inf, :use, :disp] )                     

  #Unpack some of the optimization data
  U = opt_data.U
  Name_selected_units = [string(x) for x in opt_data.Name_selected_units] #Extract and convert into a vector of strings
  td = opt_data.dat_t #Techno-economic data
  sd = opt_data.dat_sub #Subset data
  pd = opt_data.dat_p #Profile data
  scd = opt_data.dat_scen #Scenario data
  T = scd.T

  X = opt_results.Flows
  Sold = opt_results.Sold
  Bought = opt_results.Bought
  Capacity = opt_results.Capacity

  if model == "LP_2obj"
    Costs = opt_results.Objectives[:costs]
  else
    Costs = opt_results.Costs
  end

  #Function to scale cost units to the default unit (i.e. Millions) and apply a conversion rate
  scale_c(value) = scale_cost_units(value, results_currency_multiplier; force_unit = default_results_cost_scale)

  # Initialization
  Result = Dict{Symbol, Any}()
  #Numeric results
  for name in (
      :fuelprice, :fuelprice_t, :fixedOM, :varOM, :investment, :investment_annualised, :production, 
      :TotCO2tax_up, :TotCO2tax_op, :CO2taxWTTup, :CO2taxWTTop, :CO2WTTop_treshhold, 
      :sold, :fuelsold_t, :prodcost, :capacity, :el_cons, :costs, :cost_unit, :load_average,
      :FLH, :prodcost_fuel_kg, :prodcost_fuel_GJ, :prodcost_fuel_MWh,
      :prodcost_perunit, :CO2_proc_reg_t, :CO2_regulated,
      :CO2_perunitfuel_reg, :CO2_totalperGJ_reg, :av_elec_cost
  )
      Result[name] = zeros(U)
  end

  #String results
  str_arrays = (
    :year, :location, :profile, :fuel, :electrolyser,
    :CO2_capture, :CSP_tech, :power_TS, :sim_hours,
    :CO2_count_method_reg, :rencrit, :crit_app, :scenario,
    :unit_capacity, :unit_production
    )
  for name in str_arrays
      Result[name] = Array{String, 1}(undef, U)
  end

  #Lca results
  if write_lca_results == true
    for cat_symbol in opt_data.dat_lcia.impact_categories_symbol
      for phase in (:inf, :use, :disp, :total)
          Result[Symbol(string(cat_symbol) * "_" * String(phase))] = zeros(U)
      end
    end
    #Result[:climate_change_with_grid] = zeros(U)
  end

  unit_el_cons =  unit_prod_kg = unit_tot_energyJ = unit_tot_energyWh = ""

  # Sum values for profile dependent results

  # Hourly electricity purchases from the grid
  if sd.Grid_buy[1] > 0 && sd.Grid_buy_p[1] > 0
      for u = 1:sd.nGb
        Result[:fuelprice_t][sd.Grid_buy[u]] =
          scale_c(
            sum(pd.Price_Profile[sd.Grid_buy_p[u], t] * Bought[sd.Grid_buy[u], t] * pd.Renewable_criterion_profile[t] for t = 1:T) +
            sum(pd.Price_Profile[sd.Grid_buy_p[u], t] * Bought[sd.Grid_buy[u], t] * (1 - pd.Renewable_criterion_profile[t]) for t = 1:T)
             )
      end
  end

  # Hourly heat purchases
  if sd.Hourly_heat_buy[1] > 0 && sd.Heat_buy_p[1] > 0
      for u = 1:sd.nHb
          Result[:fuelprice_t][sd.Hourly_heat_buy[u]] =
            scale_c(
                sum(pd.Price_Profile[sd.Heat_buy_p[u], t] * Bought[sd.Hourly_heat_buy[u], t] for t = 1:T)
            )
      end
  end

  # Electricity sales to the grid
  if scd.Option_hourly_elec_sale && sd.Grid_sell[1] > 0 && sd.Grid_sell_p[1] > 0
      for u = 1:sd.nGs
          Result[:fuelsold_t][sd.Grid_sell[u]] =
              scale_c(
                sum(pd.Price_Profile[sd.Grid_sell_p[u], t] * Sold[sd.Grid_sell[u], t] for t = 1:T)
              )
      end
  end

  # Heat sales
  if scd.Option_hourly_heat_sale && sd.Heat_sell[1] > 0 && sd.Heal_sell_p[1] > 0
      for u = 1:sd.nHs
          Result[:fuelsold_t][sd.Heat_sell[u]] =
          scale_c(
              sum(pd.Price_Profile[sd.Heat_sell_p[u], t] * Sold[sd.Heat_sell[u], t] for t = 1:T)
           )
      end
  end

  # Regulated CO₂ accounting
  if sd.Grid_CO2_regulated_p[1] > 0 && sd.Grid_buy[1] > 0
      for u = 1:sd.nGCO2reg
          Result[:CO2_proc_reg_t][sd.Grid_in[u]] =
              sum(pd.CO2_profile_regulated[sd.Grid_CO2_regulated_p[u], t] * Bought[sd.Grid_buy[u], t] for t = 1:T) #In kg CO2e
      end
  end

  # Write the results in a table
  for u = 1:U
    #Scenario data
    Result[:scenario][u]              = scd.Scenario_name
    Result[:year][u]                  = scd.Year
    Result[:location][u]              = scd.Location
    Result[:profile][u]               = scd.Profile_name
    Result[:fuel][u]                  = scd.Fuel
    Result[:electrolyser][u]          = scd.Electrolyser
    Result[:CO2_capture][u]           = scd.CO2_capture
    Result[:CSP_tech][u]              = scd.CSP_tech
    Result[:power_TS][u]              = scd.Power_TS
    Result[:sim_hours][u]             = scd.Sim_hours
    Result[:CO2_count_method_reg][u]  = scd.CO2_count_method_reg
    Result[:CO2taxWTTup][u]           = scd.CO2taxWTTup
    Result[:CO2taxWTTop][u]           = scd.CO2taxWTTop
    Result[:CO2WTTop_treshhold][u]    = scd.CO2WTTop_treshhold
    Result[:rencrit][u]               = scd.Current_rencrit
    Result[:crit_app][u]              = string(scd.Criterion_application)

    Result[:capacity][u], Result[:unit_capacity][u] = scale_mass_power_energy_units(Capacity[u], td.Capacity_units[u];force_unit_prefix = default_results_capacity_units)
    Result[:investment][u]            = scale_c(td.Invest[u] * Capacity[u])
    Result[:investment_annualised][u] = Result[:investment][u] * td.Annuity_factor[u]
    Result[:fixedOM][u]               = scale_c(td.FixOM[u] * Capacity[u])
    Result[:varOM][u]                 = scale_c(sum(td.VarOM[u] * X[u, t] for t =1:T))
    Result[:TotCO2tax_up][u]          = scale_c(scd.CO2taxWTTup * td.CO2_inf_reg[u] * Capacity[u])
    Result[:TotCO2tax_op][u]          = scale_c(sum(scd.CO2taxWTTop * td.CO2_proc_fixed_reg[u] * X[u, t] for t =1:T) + scd.CO2taxWTTop * Result[:CO2_proc_reg_t][u])
    Result[:fuelprice][u]             = scale_c(sum(td.Fuel_Buying_fixed[u] * Bought[u, t] for t =1:T)) + Result[:fuelprice_t][u]
    Result[:sold][u]                  = - scale_c(sum(td.Fuel_Selling_fixed[u] * Sold[u, t] for t =1:T)) + Result[:fuelsold_t][u]
    Result[:cost_unit][u]             = Result[:investment_annualised][u] + Result[:fixedOM][u] + Result[:varOM][u] + 
                                        Result[:fuelprice][u] + Result[:sold][u] +
                                        Result[:TotCO2tax_up][u] + Result[:TotCO2tax_op][u]
    Result[:production][u], Result[:unit_production][u] = scale_mass_power_energy_units(sum(X[u, t] for t =1:T), td.Output_units[u]; force_unit_prefix = default_results_production_units)
    Result[:el_cons][u], unit_el_cons = scale_mass_power_energy_units(sum(td.Sc_nom[u]*X[u,t] for t =1:T),td.Output_units[sd.PU[1]] ; force_unit_prefix = default_results_production_units)
    Result[:FLH][u]                   = sum(X[u, t] / Capacity[u] for t =1:T)
    Result[:load_average][u]          = Result[:FLH][u] / T
    Result[:prodcost_perunit][u]      = Result[:production][u] == 0 ? 0 : Result[:cost_unit][u] / Result[:production][u]
    Result[:CO2_regulated][u]         = Capacity[u]*td.CO2_inf_reg[u] + Result[:production][u] * td.CO2_proc_fixed_reg[u] + Result[:CO2_proc_reg_t][u] #Units should be fixed here
      
    #********* Add the Lca results (optional)************
    if write_lca_results == true && !isnothing(opt_data.dat_lcia)
      add_lcia_results!(Result, opt_data, opt_results, u)
    end
  end

  # Post-processing for CO₂ intensity regulated and production costs
  total_fuel_energy = sum(Result[:production][i] for i in sd.MainFuel) * Fuel_energy_content_list[scd.Fuel]

  for u in 1:U
      Result[:CO2_perunitfuel_reg][u] = Result[:CO2_regulated][u] / total_fuel_energy
      Result[:CO2_totalperGJ_reg][u] = Result[:CO2_regulated][u] / (Result[:production][u] * Fuel_energy_content_list[scd.Fuel])
  end

  av_elec_cost_1 = 1e3 * sum(Result[:prodcost_perunit][u] * Result[:production][u] for u in sd.PU) /
                    sum(Result[:production][u] for u in sd.PU)
  
  for u in sd.MainFuel
    yearly_prod_kg, unit_prod_kg = scale_mass_power_energy_units(sum(X[u, t] for t =1:T), td.Output_units[u]; force_unit_prefix = "kg") #Convert yearly production in kilos
    total_energy_content_GJ, unit_tot_energyJ = scale_mass_power_energy_units(yearly_prod_kg * Fuel_energy_content_list[scd.Fuel],"MJ$(scd.Fuel)"; force_unit_prefix="GJ") #Convert in GJ fuel per year
    total_energy_content_MWh, unit_tot_energyWh = scale_mass_power_energy_units(yearly_prod_kg * Fuel_energy_content_list[scd.Fuel]/3.6,"kWh$(scd.Fuel)"; force_unit_prefix="MWh") #Convert in MWh fuel per year
    Result[:prodcost_fuel_kg][u] = scale_cost_units(Costs,results_currency_multiplier; force_unit ="") / yearly_prod_kg #Force results in currency per kg 
    Result[:prodcost_fuel_GJ][u]   = scale_cost_units(Costs,results_currency_multiplier; force_unit ="") / total_energy_content_GJ #Results in currency per GJ
    Result[:prodcost_fuel_MWh][u]  = scale_cost_units(Costs,results_currency_multiplier; force_unit ="") / total_energy_content_MWh #Results in currency per MWh
    Result[:av_elec_cost][u] = av_elec_cost_1
  end


  cols = [
    Result[:scenario], Name_selected_units, Result[:year], Result[:location], Result[:profile], Result[:power_TS],
    Result[:fuel], Result[:electrolyser], Result[:CO2_capture], Result[:CSP_tech], Result[:sim_hours],
    Result[:CO2_count_method_reg], Result[:CO2taxWTTup], Result[:CO2taxWTTop], 
    Result[:CO2WTTop_treshhold], Result[:rencrit], Result[:crit_app],
    Result[:capacity], Result[:unit_capacity], Result[:investment], Result[:investment_annualised], Result[:fixedOM], Result[:varOM],
    Result[:TotCO2tax_up], Result[:TotCO2tax_op], Result[:fuelprice], Result[:sold], Result[:cost_unit],
    Result[:production], Result[:unit_production], Result[:el_cons], Result[:load_average], Result[:FLH],
    Result[:prodcost_fuel_kg], Result[:prodcost_fuel_GJ], Result[:prodcost_fuel_MWh], Result[:av_elec_cost],
    Result[:CO2_regulated], Result[:CO2_totalperGJ_reg]
  ]
  
  Result_name = [
      "Scenario", "Type of unit", "Year data", "Location", "Profile", "Power time series name", "Fuel", "Electrolyser",
      "CO2 capture", "CSP technology", "Simulation hours", "Hourly CO2 accounting method for regulation", 
      "CO2 tax level upstream (EUR/kgCO2)", "CO2 tax level operational (EUR/kgCO2)", 
      "Max yearly emission treshhold", "Renewable criterion", "Criterion application",
      "Installed capacity", "Units Capacity", 
      "Total investment ($(default_results_cost_scale*results_currency))", "Annualised investment ($(default_results_cost_scale*results_currency))",
      "Fixed O&M ($(default_results_cost_scale*results_currency))", "Variable O&M ($(default_results_cost_scale*results_currency))", 
      "CO2 tax infrastructure ($(default_results_cost_scale*results_currency))", "CO2 tax process ($(default_results_cost_scale*results_currency))", 
      "Fuel cost ($(default_results_cost_scale*results_currency))", "Sale ($(default_results_cost_scale*results_currency))", 
      "Cost per unit ($(default_results_cost_scale*results_currency))",
      "Yearly production", "Units production", "Electricity consumption ($unit_el_cons)", 
      "Load average", "Full load hours",
      "Production cost fuel ($results_currency/$unit_prod_kg)", 
      "Production cost fuel ($results_currency/$unit_tot_energyJ)", "Production cost fuel ($results_currency/$unit_tot_energyWh)", "Av electricity cost(Euros/MWh)",
      "Regulated CO2e per unit (kgCO2e/GJfuel)", "Regulated CO2e all system (kg CO2e/GJfuel)"
  ]
  
  if write_lca_results && !isnothing(opt_data.dat_lcia)
    append_lcia_columns!(cols, Result_name, Result, opt_data)
  end

  df_results = DataFrame(cols, :auto)
  rename!(df_results, Result_name)

  # Drop columns where all entries are "None"
  cols_to_keep = [col for col in names(df_results) if any(x -> x != "None", df_results[:, col])]
  df_results = select(df_results, cols_to_keep)

  #Drop unwanted phase columns
  if write_lca_results && !isempty(remove_lcia_phases)
      remove_lcia_columns!(df_results, opt_data.dat_lcia, remove_lcia_phases)
  end

  println("remove lcia phase: $remove_lcia_phases")

  if model == "LP_2obj"

    # Create the folder to write the results if it does not exists
    pareto_main_results_folder = joinpath(pareto_results_folder,"Main results","Scenario_$(N_scen)")
    if !isdir(pareto_main_results_folder)
      mkpath(pareto_main_results_folder)
    end
    results_file = "Sol_$(Sol_number).csv"
    CSV.write(joinpath(pareto_main_results_folder, results_file), df_results)

  else
    # Create the folder to write the results if it does not exists
    main_results_folder = joinpath(resultsfolder,scd.Result_folder_name,"Main results")
    if !isdir(main_results_folder)
      mkpath(main_results_folder)
    end
    results_file = "Scenario_$(N_scen).csv"
    CSV.write(joinpath(main_results_folder, results_file), df_results)
  end
end

function add_lcia_results!(Result::Dict{Symbol,Any}, opt_data, opt_results, u::Int)
  U = opt_data.U
  td = opt_data.dat_t #Techno-economic data
  sd = opt_data.dat_sub #Subset data
  pd = opt_data.dat_p #Profile data
  scd = opt_data.dat_scen #Scenario data
  scores = opt_data.dat_lcia.scores
  T = opt_data.dat_scen.T

  X = opt_results.Flows
  Bought = opt_results.Bought
  Capacity = opt_results.Capacity  

  # Fill LCA results for unit u
  for (cat_sym, impacts) in scores
    inf_val  = u <= length(impacts.inf)  ? impacts.inf[u]  * Capacity[u] : 0.0
    use_val  = u <= length(impacts.use)  ? sum(impacts.use[u] * X[u,t] for t = 1:T) : 0.0
    disp_val = u <= length(impacts.disp) ? impacts.disp[u] * Capacity[u] : 0.0
    total_val = inf_val + use_val + disp_val

    Result[Symbol(string(cat_sym) * "_inf")][u]   = inf_val
    Result[Symbol(string(cat_sym) * "_use")][u]   = use_val
    Result[Symbol(string(cat_sym) * "_disp")][u]  = disp_val
    Result[Symbol(string(cat_sym) * "_total")][u] = total_val
  end
  #=

  Result[:climate_change_with_grid][u] = 
  sum(pd.CO2_profile_emitted[sd.Grid_CO2_emitted_p[u],t]*Bought[sd.Grid_buy[u],t] for u=1:sd.nGCO2em,t=1:T if sd.Grid_CO2_emitted_p[u] > 0)
  + sum(scores[:climate_change].inf[u]*Capacity[u] for u=1:U)
  + sum(scores[:climate_change].use[u]*X[u,t] for u=1:U,t=1:T)
  + sum(scores[:climate_change].disp[u] * Capacity[u] for u=1:U)
  =#

end

function append_lcia_columns!(cols::Vector, Result_name::Vector{String}, Result::Dict{Symbol,Any}, opt_data)
    lcia = opt_data.dat_lcia

    for cat_sym in lcia.impact_categories_symbol
        cat_name = String(cat_sym)

        # Append column data
        for phase in (:inf, :use, :disp, :total)
            push!(cols, Result[Symbol(cat_name * "_" * String(phase))])
        end

        # Append readable column names
        append!(Result_name, [
            cat_name * " (infra)",
            cat_name * " (use)",
            cat_name * " (disposal)",
            cat_name * " (total)"
        ])
    end
end

"""
    remove_lcia_columns!(df::DataFrame, lcia_data; remove_phases = Symbol[])

Remove selected LCIA phase columns (e.g. `[:inf, :use]`) from `df`.

If `remove_phases` is empty, nothing is removed.
"""
function remove_lcia_columns!(df::DataFrame, lcia_data, remove_phases::Vector{Symbol})

    isempty(remove_phases) && return df  # nothing to remove

    # Map phase symbols to their text labels
    phase_labels = Dict(
        :inf   => " (infra)",
        :use   => " (use)",
        :disp  => " (disposal)",
        :total => " (total)"
    )

    existing_cols = Set(names(df))
    to_remove = String[]

    for cat_sym in lcia_data.impact_categories_symbol
        cat_name = String(cat_sym)
        for phase in remove_phases
            if haskey(phase_labels, phase)
                col_name = cat_name * phase_labels[phase]
                if col_name in existing_cols
                    push!(to_remove, col_name)
                end
            end
        end
    end

    # Remove columns if found
    if !isempty(to_remove)
        select!(df, Not(to_remove))
    end

    return df
end


end #Module
