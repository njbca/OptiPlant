module Run_multi_scenarios_para
    
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

export run_single_scenario, run_optimization_scenarios_parallel

function run_single_scenario(
    N_scen,
    datafoldername,
    techno_eco_filename,
    scenario_set,
    solver,
    model,
    scenarios_to_run,
    profiles_filename,
    resultsfolder,
    save_input_technoeco,
    save_input_profiles,
    results_currency,
    results_currency_multiplier,
    default_results_cost_scale,
    default_results_capacity_units,
    default_results_production_units
)

    # --- load techno-economic file locally ---
    Datafile_techno_economics = joinpath(@__DIR__, "..", "data", datafoldername, "model_inputs", techno_eco_filename*".xlsx")
    wb_techno = XLSX.readxlsx(Datafile_techno_economics)
    Available_sheets_techno = XLSX.sheetnames(wb_techno)

    # --- extract scenario ---
    scen_data = build_scenario_opt_data(wb_techno, scenario_set, Available_sheets_techno, scenarios_to_run[N_scen])

    # --- load profile file locally ---
    if profiles_filename == "Check_techno_eco"
        if scen_data.Profile_folder_name == "None"
            Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", scen_data.Profile_name*".xlsx")
        else
            Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", scen_data.Profile_folder_name, scen_data.Profile_name*".xlsx")
        end
    else
        Datafile_profile = joinpath(@__DIR__, "..", "data", datafoldername, "profiles", profiles_filename*".xlsx")
    end
    wb_profile = XLSX.readxlsx(Datafile_profile)
    Available_sheets_profiles = XLSX.sheetnames(wb_profile)

    # Techno data + modifications
    techno_scen_data = load_and_locate_techno_data(wb_techno, Available_sheets_techno, scen_data,
                                                   key_terms_technoeco, key_terms_selected_units, key_terms_scenarios)
    Data_units_filtered, Data_sources_filtered, Name_selected_units, U = filter_units(techno_scen_data, scen_data)
    apply_scenario_changes!(Data_units_filtered, Name_selected_units, techno_scen_data, scen_data)

    # Profiles
    profile_data = load_and_locate_profile_data(wb_profile, Available_sheets_profiles, key_terms_profiles)
    profile_data_filtered = filter_all_profile_data(profile_data, scen_data)

    # Optimization input
    dat_sub, dat_t, dat_t_sources, dat_p = build_optimization_data(Data_units_filtered, Data_sources_filtered,
                                                                   techno_scen_data, profile_data, profile_data_filtered,
                                                                   scen_data, U)
    apply_scenario_options!(dat_sub, dat_t, dat_p, scen_data)

    opt_data = (dat_sub = dat_sub, dat_t = dat_t, dat_t_sources = dat_t_sources,
                dat_p = dat_p, dat_scen = scen_data, Name_selected_units = Name_selected_units, U = U)

    # Save input if needed
    if save_input_profiles || save_input_technoeco
        write_input_data(opt_data, save_input_technoeco, save_input_profiles, resultsfolder, N_scen)
    end

    if model == "LP"
      # Solve
      opt_results = Solve_OptiPlant_LP(opt_data, solver)

      # Write results
      if scen_data.Write_flows || scen_data.Write_sold_products || scen_data.Write_fuel_cost
          write_hourly_results_LP(opt_data, opt_results, N_scen, resultsfolder, results_currency_multiplier)
      end
      write_main_results_LP(opt_data, opt_results, N_scen, resultsfolder, results_currency, results_currency_multiplier,
                        default_results_cost_scale, default_results_capacity_units, default_results_production_units)
    end
    return "Scenario $N_scen done"
end


function run_optimization_scenarios_parallel(
    datafoldername::String,
    techno_eco_filename::String,
    scenario_set::String,
    solver::String,
    scenarios_to_run;
    profiles_filename::String = "Check_techno_eco",
    results_currency::String = "EUR",
    results_currency_multiplier::Float64 = 1.0,
    default_results_cost_scale = "M",
    default_results_capacity_units = "t or MW or MWh",
    default_results_production_units = "kt or GWh",
    save_input_technoeco::Bool = true,
    save_input_profiles::Bool = true
)

    # Paths
    Datafile_techno_economics = joinpath(@__DIR__, "..", "data", datafoldername, "model_inputs", techno_eco_filename*".xlsx")
    resultsfolder = joinpath(@__DIR__, "..", "results", datafoldername)

    # Load techno data once (shared, read-only)
    wb_techno = XLSX.readxlsx(Datafile_techno_economics)
    Available_sheets_techno = XLSX.sheetnames(wb_techno)

    # Parallel execution
    results = pmap(N_scen -> run_single_scenario(
                        N_scen,
                        datafoldername,
                        techno_eco_filename,
                        scenario_set,
                        solver,
                        model,
                        scenarios_to_run,
                        profiles_filename,
                        resultsfolder,
                        save_input_technoeco,
                        save_input_profiles,
                        results_currency,
                        results_currency_multiplier,
                        default_results_cost_scale,
                        default_results_capacity_units,
                        default_results_production_units),
                   scenarios_to_run)

    return "Successful execution of $(length(results)) scenarios, results in $resultsfolder"
end

end