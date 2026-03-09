using Test
#using Distributed
using OptiPlantPtX

@testset "OptiPlantPtX.jl" begin

    @testset "Example run LP" begin
        result = run_optimization_scenarios(
            "Example", #Name of the data folder
            "Input_data_example", #Excel file with model inputs
            "ScenariosToRun", #Excel sheet with scenarios
            "HiGHS", #Solver
            1:2; #Scenarios to run
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end

    @testset "Sequential run LP" begin
        result = run_optimization_scenarios(
            "Full_model",
            "Full_data",
            "ScenariosToRun",
            "HiGHS",
            3:4;
            profiles_filename = "All_locations/2019_CO2",
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end

    @testset "Sequential run LP_2obj" begin
        result = run_optimization_scenarios(
            "Full_model",
            "Full_data",
            "ScenariosToRun",
            "HiGHS",
            [1];
            model = "LP_2obj", #LP_2obj
            N_pareto_points = 6,
            interior_points = 2,
            objective1 = "costs",
            objective2 = "emissions_CO2e_regulated", #Choose emissions_CO2e_regulated or an impact category symbol from the lcia file
            profiles_filename = "All_locations/2019_CO2",
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)

    end

        #=
    @testset "Ammonia paper" begin
        result = run_optimization_scenarios(
            "Ammonia_paper", #Name of the data folder
            "Data_ammonia_paper", #Excel file with model inputs
            "ScenariosToRun", #Excel sheet with scenarios
            "HiGHS", #Solver
            1:2; #Scenarios to run
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end

    @testset "CSP paper" begin
        result = run_optimization_scenarios(
            "CSP_paper", #Name of the data folder
            "Data_CSP_paper", #Excel file with model inputs
            "ScenariosToRun", #Excel sheet with scenarios
            "HiGHS", #Solver
            1:2; #Scenarios to run
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end

    @testset "Meas sim paper" begin
        result = run_optimization_scenarios(
            "Meas_vs_sim_paper", #Name of the data folder
            "Meas_vs_sim_data", #Excel file with model inputs
            "ScenariosToRun", #Excel sheet with scenarios
            "HiGHS", #Solver
            1:2; #Scenarios to run
            save_input_profiles = false,
            save_input_technoeco = false
        )
        @test occursin("Successful execution", result)
    end
    =#
    
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
