module Run_multi_scenarios

include("ReadData/opt_data/CombinedOptData.jl")
include("ReadData/opt_data/LciaOptData.jl")
include("ReadData/opt_data/ProfilesOptData.jl")
include("ReadData/opt_data/ScenariosOptData.jl")
include("ReadData/opt_data/TechnoEcoOptData.jl")

include("ReadData/user_defined/Names.jl")
include("SolveModel/Solve_LP.jl")
include("WriteResults/Results_LP.jl")
include("SolveModel/Solve_LP_2obj.jl")

using JuMP, CSV, DataFrames, XLSX, Gurobi, HiGHS
using .CombinedOptData, .LciaOptData, .ProfilesOptData, .ScenariosOptData, .TechnoEcoOptData
using .Solve_LP, .Solve_LP_2obj
using .Results_LP

export run_optimization_scenarios

function run_optimization_scenarios(
    datafoldername::String,
    techno_eco_filename::String,
    scenario_set::String,
    solver::String,
    scenarios_to_run;
    model::String = "LP", #LP_2obj
    N_pareto_points::Int = 10,
    interior_points::Int=2,
    objective1::String="costs",
    objective2::String="emissions_CO2e_regulated",
    profiles_filename::String = "Check_techno_eco",
    lcia_filename::String = "Check_techno_eco",
    results_currency::String = "EUR",
    results_currency_multiplier::Float64 = 1.0,
    default_results_cost_scale = "M", #Million
    default_results_capacity_units = "t or MW or MWh",
    default_results_production_units = "kt or GWh",
    save_input_technoeco::Bool = true,
    save_input_profiles::Bool = true   
)

    N_scen_total = length(scenarios_to_run)

    # Default paths
    Datafile_techno_economics = joinpath(@__DIR__, "..", "data", datafoldername, "model_inputs", techno_eco_filename*".xlsx")
    resultsfolder = joinpath(@__DIR__, "..", "results", datafoldername)

    if profiles_filename != "Check_techno_eco" #If the profile name is user-defined as an option
      Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", profiles_filename*".xlsx")
      # Load profile data
      wb_profile = XLSX.readxlsx(Datafile_profile)
      Available_sheets_profiles = XLSX.sheetnames(wb_profile)
    end

    if lcia_filename != "Check_techno_eco"
      Datafile_LCIA = joinpath(@__DIR__, "..", "data", datafoldername,"lcia_data",lcia_filename*".xlsx")
      # Load lcia data
      wb_lcia = XLSX.readxlsx(Datafile_LCIA)
      Available_sheets_lcia = XLSX.sheetnames(wb_lcia)
    end

    # Load techno-economic data
    wb_techno = XLSX.readxlsx(Datafile_techno_economics)
    Available_sheets_techno = XLSX.sheetnames(wb_techno)

    for N_scen in 1:N_scen_total
      # Extract scenario data
      scen_data = build_scenario_opt_data(wb_techno, scenario_set, Available_sheets_techno, scenarios_to_run[N_scen])

      # If defined by the user in the excel, get profile data from the scenario list (inconvenient: open the file at each iteration)
      if profiles_filename == "Check_techno_eco"
        if scen_data.Profile_folder_name == "None"
          Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", scen_data.Profile_name*".xlsx")
        else
          Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", scen_data.Profile_folder_name, scen_data.Profile_name*".xlsx")
        end
        wb_profile = XLSX.readxlsx(Datafile_profile)
        Available_sheets_profiles = XLSX.sheetnames(wb_profile)
      end

      if lcia_filename == "Check_techno_eco"
        if scen_data.Lcia_filename != "None"
          Datafile_LCIA = joinpath(@__DIR__, "..", "data", datafoldername, "lcia_data", scen_data.Lcia_filename*".xlsx")
          wb_lcia = XLSX.readxlsx(Datafile_LCIA)
          Available_sheets_lcia = XLSX.sheetnames(wb_lcia)
        end
      end

      # Get techno-economic data and apply scenario modifications
      techno_scen_data = load_and_locate_techno_data(wb_techno, Available_sheets_techno, scen_data, key_terms_technoeco, key_terms_selected_units, key_terms_scenarios)

      Data_units_filtered, Data_sources_filtered, Name_selected_units, U = filter_units(techno_scen_data, scen_data)
      apply_scenario_changes!(Data_units_filtered, Name_selected_units, techno_scen_data, scen_data)

      # Get profile data
      profile_data = load_and_locate_profile_data(wb_profile, Available_sheets_profiles, key_terms_profiles)
      profile_data_filtered = filter_all_profile_data(profile_data, scen_data)

      #Get lcia data if it exists
      # Initialize LCIA-related variables to safe defaults in case no LCIA is provided
      lcia_data = nothing
      Data_lcia_filtered = nothing
      if scen_data.Lcia_filename != "None"
        lcia_data = load_and_locate_lcia_data(wb_lcia, Available_sheets_lcia, key_terms_lcia)
        Data_lcia_filtered = filter_lcia_data(Data_units_filtered, techno_scen_data, lcia_data)
        #dat_lcia = build_lcia_opt_data(Data_lcia_filtered, lcia_data)
      end

      # Build optimization input data
      dat_sub, dat_t, dat_t_sources, dat_p, dat_lcia = build_optimization_data(
        Data_units_filtered,
        Data_sources_filtered, 
        techno_scen_data, 
        profile_data, 
        profile_data_filtered,
        lcia_data,
        Data_lcia_filtered,
        scen_data,
        U
      )
      apply_scenario_options!(dat_sub, dat_t, dat_p, scen_data)

      opt_data = (
          dat_sub = dat_sub,
          dat_t = dat_t,
          dat_t_sources = dat_t_sources,
          dat_p = dat_p,
          dat_lcia = dat_lcia,
          dat_scen = scen_data,
          Name_selected_units = Name_selected_units,
          U = U
      )

      # Save input data if needed
      if save_input_profiles || save_input_technoeco
        write_input_data(opt_data, save_input_technoeco, save_input_profiles, resultsfolder, N_scen)
      end

      # Solve the model and write the results as csv
      if model == "LP"
        opt_results = Solve_OptiPlant_LP(opt_data, solver)
        if scen_data.Write_flows || scen_data.Write_sold_products || scen_data.Write_fuel_cost
          write_hourly_results_LP(opt_data, opt_results, N_scen, resultsfolder, results_currency_multiplier,)
        end
        # Only write LCIA/LCA results if LCIA data is available
        write_main_results_LP(opt_data, opt_results, N_scen, resultsfolder, results_currency, results_currency_multiplier, 
          default_results_cost_scale, default_results_capacity_units, default_results_production_units; write_lca_results = !isnothing(opt_data.dat_lcia))
      
      elseif model == "LP_2obj" 
        generate_adaptive_pareto_curve(opt_data, solver, N_scen, resultsfolder,
                                        results_currency, results_currency_multiplier,
                                        default_results_cost_scale,
                                        default_results_capacity_units,
                                        default_results_production_units,
                                        N_pareto_points,
                                        interior_points,
                                        objective1,
                                        objective2)
      end
    end
  return "Successful execution, results available in $resultsfolder"
end

end #Module