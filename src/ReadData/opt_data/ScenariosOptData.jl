module ScenariosOptData

using XLSX, DataFrames

include("../helpers/HelperFunctions.jl")

include("../user_defined/Names.jl")

export scenario_opt_data, build_scenario_opt_data

struct scenario_opt_data
    Scenario_name::String
    Scenario::String
    Year::String
    Profile_name::String
    Profile_folder_name::String
    Location::String
    Fuel::String
    Electrolyser::String
    CO2_capture::String
    CSP_tech::String
    Water_supply::String
    H2_storage::String
    Power_TS::String
    CO2_count_method_reg::String
    Hourly_lcia_count_method::String
    CO2taxWTTop::Float64
    CO2taxWTTup::Float64
    CO2WTTop_treshold::Float64
    Current_rencrit::String
    Criterion_application::Float64
    NonRenCostPenalty::Float64
    Lcia_filename::String
    Result_folder_name::String
    Input_data::String
    Input_ref::String
    Option_max_capacity::Bool
    Option_ramping::Bool
    Option_no_negative_prices::Bool
    Option_hourly_elec_sale::Bool
    Option_connection_limit::Bool
    Option_fixed_oxygen_sale::Bool
    Option_fixed_heat_sale::Bool
    Option_fixed_process_heat_sale::Bool
    Option_fixed_biochar_sale::Bool
    Option_fixed_CH4_sale::Bool
    Option_hourly_heat_sale::Bool
    Write_sold_products::Bool
    Write_fuel_cost::Bool
    Write_flows::Bool
    Sim_hours::String
    periodic_demand_targets::Bool
    Tbegin::Int
    TMstart::Int
    TMend::Int
    Tfinish::Int
    Time::Vector{Int}
    T::Int
    Tstart::Vector{Int}
    T_period::Union{Nothing, Vector{Vector{Int}}}  # only set if periodic
    Time_demand_target::Union{Nothing, Matrix{Int}} # only set if periodic
    Configuration_scenario::String
end

"""
    build_scenario_opt_data(wb_techno, Scenarios_set, Available_sheets_techno, N_scen::Int)

Builds a structured scenario data object from a scenario definition sheet in the technology workbook.

This function loads a specified scenario from the workbook and extracts all relevant parameters,
including general scenario metadata, profiles, system configuration, CO₂ regulation settings,
file references, solver options, and simulation horizon details. It returns a `scenario_opt_data`
object that consolidates these inputs for use in optimization and simulation.

# Arguments
- `wb_techno`: Workbook handle containing the technology and scenario definition sheets.
- `Scenarios_set`: Name of the sheet or dataset containing scenario definitions.
- `Available_sheets_techno`: List of available sheets in the workbook (used for validation).
- `N_scen::Int`: Index of the scenario to extract from the dataset.

# Returns
A `scenario_opt_data` object containing:
- **General scenario info**: `Scenario_name`, `Scenario`, `Year`
- **Profiles**: `Profile_name`, `Profile_folder_name`, `Location`
- **System configuration**: `Fuel`, `Electrolyser`, `CO2_capture`, `CSP_tech`, `Water_supply`, `H2_storage`, `Power_TS`
- **CO₂ regulation**: `CO2_count_method_reg`, `Hourly_lcia_count_method`, `CO2taxWTTop`, `CO2taxWTTup`,
  `CO2WTTop_treshold`, `Current_rencrit`, `Criterion_application`, `NonRenCostPenalty`
- **Files and references**: `Lcia_filename`, `Result_folder_name`, `Input_data`, `Input_ref`
- **Options**: Capacity, ramping, negative prices, product sales options, output toggles, etc.
- **Simulation hours**: `Sim_hours`, time horizon (`Time`, `T`, `Tstart`), demand target structure (`T_period`, `Time_demand_target`), and periodicity flag (`periodic_demand_targets`)
- **Configuration summary**: `Configuration_scenario`

# Notes
- Simulation horizon is parsed from `Sim_hours` if provided. Supports:
  - Four-value input: `Tbegin, TMstart, TMend, Tfinish`
  - Two-value input: `Number_of_periods, Hours_per_period`
  - Default yearly target: `"72,4000,4876,8760"`
- The returned configuration string `Configuration_scenario` concatenates technology choices for easy identification.
- Missing or unused parameters (e.g. `CSP_tech = "None"`) are handled gracefully.
"""


# Main function
function build_scenario_opt_data(wb_techno, Scenarios_set, Available_sheets_techno, N_scen::Int)

    #Load the sheet with all the scenarios
    Data_scenarios = read_xlsx_sheet(wb_techno, Scenarios_set, Available_sheets_techno; warn=true)

    # Get the first line of the scenarios list
    L1_scenario = findfirst(x -> x == ScenarioTags.scenario_number, Data_scenarios)[1] + 1

    # Column indices helper
    get_col(name) = isnothing(findfirst(x -> x == name, Data_scenarios)) ? nothing : findfirst(x -> x == name, Data_scenarios)[2]

    # Unified wrapper
    getval(x; default=nothing, as_string=false) = get_scenario_element_or_default(
        safe_extract_col(Data_scenarios, L1_scenario, get_col(x); as_string=as_string),
        N_scen;
        default=default
    )


    # Usage
    Scenario_name = getval(ScenarioTags.scenario_name; default="None", as_string=true)
    Scenario      = getval(ScenarioTags.scenario; default="None", as_string=true)
    Year          = getval(ScenarioTags.year_data; default="None", as_string=true)

    # Profiles
    Profile_name       = getval(ScenarioTags.profile_name; default="None", as_string=true)
    Profile_folder_name= getval(ScenarioTags.profile_folder_name; default="None", as_string=true)
    Location           = getval(ScenarioTags.location; default="None", as_string=true)

    # System configuration
    Fuel         = getval(ScenarioTags.fuel; default="None", as_string=true)
    Electrolyser = getval(ScenarioTags.electrolyser; default="None", as_string=true)
    CO2_capture  = getval(ScenarioTags.co2_capture; default="None", as_string=true)
    CSP_tech     = getval(ScenarioTags.csp_tech; default="None", as_string=true)
    Water_supply = getval(ScenarioTags.water_supply; default="None", as_string=true)
    H2_storage   = getval(ScenarioTags.h2_storage; default="None", as_string=true)
    Power_TS     = getval(ScenarioTags.power_ts; default="None", as_string=true)

    # CO2 regulation
    CO2_count_method_reg = getval(ScenarioTags.co2_count_method_reg; default="None", as_string=true)
    CO2taxWTTop          = getval(ScenarioTags.co2_tax_wttop; default=0)
    CO2taxWTTup          = getval(ScenarioTags.co2_tax_wttup; default=0)
    CO2WTTop_treshold   = getval(ScenarioTags.co2_wttop_threshold; default="None", as_string=true)
    CO2WTTop_treshold   = isa(CO2WTTop_treshold, String) ? -1 : CO2WTTop_treshold
    Current_rencrit      = getval(ScenarioTags.renewable_criterion; default="None", as_string=true)
    Criterion_application= getval(ScenarioTags.criterion_application; default=0)

    # Hourly lcia
    Hourly_lcia_count_method  = getval(ScenarioTags.hourly_lcia_count_method; default="None", as_string=true)


    NonRenCostPenalty = Criterion_application == -1 ? 0 : Criterion_application

    # Files
    Lcia_filename       = getval(ScenarioTags.lcia_filename; default="None", as_string=true)
    Result_folder_name = getval(ScenarioTags.result_folder_name; default="None", as_string=true)
    Input_data         = getval(ScenarioTags.input_data_sheet; default="None", as_string=true)
    Input_ref          = getval(ScenarioTags.input_references_sheet; default="None", as_string=true)

    # Options
    Option_max_capacity       = getval(ScenarioTags.option_max_capacity; default=false)
    Option_ramping            = getval(ScenarioTags.option_ramping; default=false)
    Option_no_negative_prices = getval(ScenarioTags.option_no_negative_prices; default=true)
    Option_hourly_elec_sale   = getval(ScenarioTags.option_hourly_elec_sale; default=false)
    Option_connection_limit   = getval(ScenarioTags.option_connection_limit; default=false)
    Option_fixed_oxygen_sale  = getval(ScenarioTags.option_fixed_oxygen_sale; default=false)
    Option_fixed_heat_sale    = getval(ScenarioTags.option_fixed_heat_sale; default=false)
    Option_fixed_process_heat_sale = getval(ScenarioTags.option_fixed_process_heat_sale; default=false)
    Option_fixed_biochar_sale = getval(ScenarioTags.option_fixed_biochar_sale; default=false)
    Option_fixed_CH4_sale     = getval(ScenarioTags.option_fixed_CH4_sale; default=false)
    Option_hourly_heat_sale   = getval(ScenarioTags.option_hourly_heat_sale; default=false)
    Write_sold_products       = getval(ScenarioTags.write_sold_products; default=false)
    Write_fuel_cost           = getval(ScenarioTags.write_fuel_cost; default=false)
    Write_flows               = getval(ScenarioTags.write_flows; default=false)

    # Simulation hours
    Sim_hours = getval(ScenarioTags.simulation_hours; default=0)
    sim_h_nums = isa(Sim_hours, String) ? parse.(Int, split(Sim_hours, ",")) : 0

    if length(sim_h_nums) == 4
        periodic_demand_targets = false
        Tbegin, TMstart, TMend, Tfinish = sim_h_nums
        Time = vcat(collect(1:TMstart), collect(TMend:Tfinish))
        T = length(Time)
        Tstart = copy(Time)
        if Tbegin >= 2
            splice!(Tstart, 1:Tbegin)
        end
    elseif length(sim_h_nums) == 2
        periodic_demand_targets = true
        Number_of_periods, Hours_per_period = sim_h_nums
        T = Hours_per_period * Number_of_periods
        Time = collect(1:T)
        Time_demand_target = transpose(reshape(collect(1:T), Hours_per_period, Number_of_periods))
        T_period = [collect(row) for row in eachrow(Time_demand_target)]
        Tstart = collect(1:T)
    else
        periodic_demand_targets = false
        println("Using default simulation hours with yearly demand targets: Tbegin=72, TMstart=4000, TMend=4876, Tfinish=8760")
        Tbegin, TMstart, TMend, Tfinish = 72, 4000, 4876, 8760
        Time = vcat(collect(1:TMstart), collect(TMend:Tfinish))
        T = length(Time)
        Tstart = copy(Time)
        if Tbegin >= 2
            splice!(Tstart, 1:Tbegin)
        end
        Sim_hours = "72,4000,4876,8760"
    end

    Configuration_scenario = if isnothing(CSP_tech) || CSP_tech == "None"
        Fuel * "_" * Electrolyser * "_" * CO2_capture
    else
        Fuel * "_" * Electrolyser * "_" * CO2_capture * "_" * CSP_tech
    end

    return scenario_opt_data(
        Scenario_name,
        Scenario,
        Year,
        Profile_name,
        Profile_folder_name,
        Location,
        Fuel,
        Electrolyser,
        CO2_capture,
        CSP_tech,
        Water_supply,
        H2_storage,
        Power_TS,
        CO2_count_method_reg,
        Hourly_lcia_count_method,
        CO2taxWTTop,
        CO2taxWTTup,
        CO2WTTop_treshold,
        Current_rencrit,
        Criterion_application,
        NonRenCostPenalty,
        Lcia_filename,
        Result_folder_name,
        Input_data,
        Input_ref,
        Option_max_capacity,
        Option_ramping,
        Option_no_negative_prices,
        Option_hourly_elec_sale,
        Option_connection_limit,
        Option_fixed_oxygen_sale,
        Option_fixed_heat_sale,
        Option_fixed_process_heat_sale,
        Option_fixed_biochar_sale,
        Option_fixed_CH4_sale,
        Option_hourly_heat_sale,
        Write_sold_products,
        Write_fuel_cost,
        Write_flows,
        Sim_hours,
        periodic_demand_targets,
        Tbegin,
        TMstart,
        TMend,
        Tfinish,
        Time,
        T,
        Tstart,
        periodic_demand_targets ? T_period : nothing,
        periodic_demand_targets ? Time_demand_target : nothing,
        Configuration_scenario
    )
end

end # module