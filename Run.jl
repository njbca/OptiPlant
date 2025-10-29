using OptiPlantPtX

datafoldername = "Full_model"
techno_eco_filename = "Full_data_simple"
scenario_set = "ScenariosToRun"
solver = "Gurobi"
scenarios_to_run = 1:4 

    result = run_optimization_scenarios(
        datafoldername,
        techno_eco_filename,
        scenario_set,
        solver,
        scenarios_to_run;
        model = "LP", #LP , LP_2obj
        N_pareto_points = 12,
        interior_points = 3,
        objective1 = "costs",
        objective2 = "climate_change_with_grid", #Choose emissions_CO2e_regulated or an impact category symbol from the lcia file
        profiles_filename = "All_locations/2019_CO2",
        save_input_profiles = true,
        save_input_technoeco =  true)