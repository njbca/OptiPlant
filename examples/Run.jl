using OptiPlantPtX

datafoldername = "Full_model"
techno_eco_filename = "Full_data"
scenario_set = "ScenariosToRun"
solver = "Gurobi"
scenarios_to_run = [5] # 1:16 --> From one to 16 ; [2,4] Scenarios 2 and 4 ; [5] Scenario 5 only

result = run_optimization_scenarios(
    datafoldername,
    techno_eco_filename,
    scenario_set,
    solver,
    scenarios_to_run;
    model = "LP_2obj", #LP , LP_2obj
    N_pareto_points = 12,
    interior_points = 3,
    objective1 = "costs",
    objective2 = "climate_change", #Choose emissions_CO2e_regulated or an impact category symbol from the lcia file
    profiles_filename = "All_locations/2019_lcia_skive",
    remove_lcia_phases_from_results = Symbol[:inf,:use,:disp, :hourly], #: inf :use, :disp, :hourly, :total
    save_input_profiles = true,
    save_input_technoeco =  true,
    save_input_lcia = true)