using OptiPlantPtX

# Configuration
datafoldername = "Example"
techno_eco_filename = "Input_data_example" #or "Data_ammonia_paper"
scenario_set = "ScenariosToRun"
solver = "HiGHS"  # Change to "Gurobi" if you have the license

# Run all scenarios 1:18 (adjust the upper bound if your excel has fewer scenarios)
# To run only one scenario: scenarios_to_run = 1:1 or scenarios_to_run = 4:4
# Or any personalized vector of scenarios
scenarios_to_run = 1:1

# Run and time the execution. Wrap in try/catch so a single scenario error doesn't stop the batch.
try
    run_optimization_scenarios(
        datafoldername,
        techno_eco_filename,
        scenario_set,
        solver,
        scenarios_to_run;
        save_input_profiles = true,
        save_input_technoeco =  true)
catch e
    println("Error running scenarios: ", e)
    @show(stacktrace(catch_backtrace()))
end