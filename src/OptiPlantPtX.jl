module OptiPlantPtX

include("Run_multi_scenarios.jl")
include("Run_multi_scenarios_para.jl")
include("ImportData/Import_profiles_data.jl")
include("PlotGraphs/Launch_dashboards.jl")

using .Run_multi_scenarios
using .Run_multi_scenarios_para
using .Import_profiles_data
using .Launch_dashboards


export run_optimization_scenarios, run_optimization_scenarios_parallel,run_single_scenario,
       import_profiles,
       launch_scenario_dashboard, launch_hourly_profiles_dashboard, launch_lcia_dashboard

end
