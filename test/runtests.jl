using Test
#using Distributed
using OptiPlantPtX

@testset "OptiPlantPtX.jl" begin
    datafoldername = "Full_model"
    techno_eco_filename = "Full_data_simple"
    scenario_set = "ScenariosToRun"
    solver = "HiGHS"
 
    @testset "Sequential run LP" begin
        scenarios_to_run = 3:4  # keep small for testing
        result = run_optimization_scenarios(
            datafoldername,
            techno_eco_filename,
            scenario_set,
            solver,
            scenarios_to_run;
            profiles_filename = "All_locations/2019_CO2",
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end

    @testset "Sequential run LP_2obj" begin
        scenarios_to_run = 3:3  # keep small for testing
        result = run_optimization_scenarios(
            datafoldername,
            techno_eco_filename,
            scenario_set,
            solver,
            scenarios_to_run;
            model = "LP_2obj", #LP_2obj
            N_pareto_points = 6,
            interior_points = 2,
            profiles_filename = "All_locations/2019_CO2",
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end
    #=       
    @testset "Parallel run" begin
        addprocs(2; exeflags="--project=$(Base.active_project())")  # start workers inside test
        @everywhere using OptiPlant  # load your module on all workers

        scenarios_to_run = 1:2  # same small set, parallelized
        result = run_optimization_scenarios_parallel(
            datafoldername,
            techno_eco_filename,
            scenario_set,
            solver,
            scenarios_to_run;
            profiles_filename = "All_locations/2019",
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end
    =#
end
