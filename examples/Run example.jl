using OptiPlantPtX

# Configuration
datafoldername = "Example"
techno_eco_filename = "Input_data_example" #or "Data_ammonia_paper"
scenario_set = "ScenariosToRun"
solver = "HiGHS"  # Change to "Gurobi" if you have the license

scenarios_to_run = [1] # 1:16 --> From one to 16 ; [2,4] Scenarios 2 and 4 ; [5] Scenario 5 only

run_optimization_scenarios(
    datafoldername,
    techno_eco_filename,
    scenario_set,
    solver,
    scenarios_to_run;
    save_input_profiles = true,
    save_input_technoeco =  true)