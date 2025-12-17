using OptiPlantPtX

datafoldername = "Bakkafuel"
techno_eco_filename = "Data_bakkafuel"
scenario_set = "ScenariosToRun"
solver = "Gurobi"
scenarios_to_run = 1:1  # keep small for testing

import_profile_data()

run_optimization_scenarios(
    datafoldername,
    techno_eco_filename,
    scenario_set,
    solver,
    scenarios_to_run;
    model = "LP", #LP_2obj
    #N_pareto_points = 20,
    #profiles_filename = "2019_gl",
    save_input_profiles = true,
    save_input_technoeco =  true)