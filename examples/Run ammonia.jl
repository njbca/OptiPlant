using Pkg
Pkg.activate(".")
using OptiPlantPtX
using Dates

# Configuration
datafoldername = "Ammonia_paper"
techno_eco_filename = "Data_ammonia_paper"
scenario_set = "ScenariosToRun"
solver = "Gurobi"  # change to "HiGHS" if you don't have Gurobi

# Run all scenarios 1..18 (adjust the upper bound if your excel has fewer scenarios)
scenarios_to_run = 1:18

# Run and time the execution. Wrap in try/catch so a single scenario error doesn't stop the batch.
start_time = now()
println("Starting scenarios: ", collect(scenarios_to_run))
try
    result = run_optimization_scenarios(
        datafoldername,
        techno_eco_filename,
        scenario_set,
        solver,
        scenarios_to_run;
        model = "LP", # options: "LP", "LP_2obj"
        N_pareto_points = 12,
        interior_points = 3,
        objective1 = "costs",
        objective2 = "climate_change_with_grid", # e.g. "emissions_CO2e_regulated"
        profiles_filename = "All_locations/2019",
        save_input_profiles = true,
        save_input_technoeco =  true)
    println(result)
catch e
    println("Error running scenarios: ", e)
    @show(stacktrace(catch_backtrace()))
end
println("Elapsed: ", now() - start_time)