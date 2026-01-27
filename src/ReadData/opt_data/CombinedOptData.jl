module CombinedOptData

include("../helpers/HelperFunctions.jl")

include("ScenariosOptData.jl")
include("SubsetsOptData.jl")
include("TechnoEcoOptData.jl")
include("ProfilesOptData.jl")
include("LciaOptData.jl")

using XLSX, CSV, DataFrames
using .ScenariosOptData
using .SubsetsOptData
using .TechnoEcoOptData
using .ProfilesOptData
using .LciaOptData

export build_optimization_data, write_input_data


#***************** Build the data that will be used for the optimization ***************

"""
    build_optimization_data(
        Data_units_filtered,
        Data_sources_filtered,
        techno_scen_data,
        profile_data,
        profile_data_filtered,
        scen,
        U
    )

Builds all the necessary data structures for techno-economic optimization.

This function orchestrates the creation of subsets, techno-economic parameters, 
optional source data, and profile matrices required for the optimization model. 
It combines filtered techno-economic units, scenario metadata, and profile data 
to produce structured inputs ready for use in the solver.

# Arguments
- `Data_units_filtered`: Filtered techno-economic dataset for units.
- `Data_sources_filtered`: Filtered source dataset for units (may be `nothing`).
- `techno_scen_data`: Scenario-specific metadata including indexes and corners.
- `profile_data`: Raw profile data loaded from workbook.
- `profile_data_filtered`: Profile data filtered for scenario-specific locations and conditions.
- `scen`: Scenario object specifying system configuration and options.
- `U`: Number of units retained after filtering.

# Returns
- `dat_sub`: Subset data object containing indices for units, products, storage, and profiles.
- `dat_t`: Techno-economic data object (`technoeco_opt_data`) for the retained units.
- `dat_t_sources`: Techno-economic data from sources (string-based) or `nothing` if not provided.
- `dat_p`: Profile data object (`profiles_opt_data`) containing fluxes, prices, CO₂, and renewable criterion profiles.

# Notes
- Combines multiple helper functions:
    - `build_subsets_opt_data`
    - `build_technoeco_opt_data`
    - `build_technoeco_sources_data`
    - `build_profiles_opt_data`
- Ensures all optimization inputs are consistent with the current scenario and filtered datasets.
"""

function build_optimization_data(
    Data_units_filtered,
    Data_sources_filtered,
    techno_scen_data,
    profile_data,
    profile_data_filtered,
    lcia_data,
    Data_lcia_filtered,
    scen,
    U
)

    if ! isnothing(Data_lcia_filtered)
        dat_lcia = build_lcia_opt_data(Data_lcia_filtered, lcia_data, Data_units_filtered, techno_scen_data, U)
    else
        dat_lcia = nothing
    end

    dat_sub = build_subsets_opt_data(
        Data_units_filtered,
        techno_scen_data,
        profile_data,
        profile_data_filtered,
        U,
        dat_lcia
    )

    dat_t = build_technoeco_opt_data(Data_units_filtered, techno_scen_data)

    if ! isnothing(Data_sources_filtered)
        dat_t_sources = build_technoeco_sources_data(Data_sources_filtered, techno_scen_data)
    else
        dat_t_sources = nothing
    end

    dat_p = build_profiles_opt_data(
        profile_data_filtered,
        profile_data,
        dat_sub,
        scen
    )

    return dat_sub, dat_t, dat_t_sources, dat_p, dat_lcia
end


#************************ Write the data used for the optimization as CSVs ****************
"""
    write_input_data(opt_data, save_input_technoeco::Bool, save_input_profiles::Bool, resultsfolder::String, Nscen::Int64)

Writes scenario-specific optimization input data to CSV files for reproducibility and record-keeping.

This function saves both profile data (fluxes, prices, CO₂, renewable criterion) and 
techno-economic data (unit parameters and optional source data) for a given scenario. 
Files are organized in a dedicated folder within the results directory.

# Arguments
- `opt_data`: Object containing all prepared optimization data:
    - `dat_sub` (subset indices)
    - `dat_t` (techno-economic data)
    - `dat_t_sources` (techno-economic source data, optional)
    - `dat_p` (profile data)
    - `dat_scen` (scenario metadata)
    - `Name_selected_units` and `U` (number of units)
- `save_input_technoeco`: `true` to save techno-economic data CSV files.
- `save_input_profiles`: `true` to save profile data CSV files.
- `resultsfolder`: Path to the main results directory.
- `Nscen`: Scenario number used for organizing output folders.

# Behavior
- Creates a subfolder `"Data used/Scenario_Nscen"` under the scenario result folder.
- Saves profile matrices as CSV files: flux, price, CO₂ (regulated and emitted), and renewable criterion.
- Saves techno-economic data for selected units, including optional source data if provided.
- Inserts unit names as the first column in techno-economic CSV files.

# Notes
- Only 1D vectors matching the number of selected units are included in the techno-economic CSV files.
- Existing files are overwritten if they already exist.
- Ensures reproducibility of the optimization setup for the given scenario.
"""


function write_input_data(opt_data, save_input_technoeco::Bool, save_input_profiles::Bool, resultsfolder::String, Nscen::Int64)

    #Unpack required optimization data
    U = opt_data.U
    Name_selected_units = [string(x) for x in opt_data.Name_selected_units] #Extract and convert into a vector of strings
    td = opt_data.dat_t #Techno-economic data
    sd = opt_data.dat_sub #Subset data
    pd = opt_data.dat_p #Profile data
    scd = opt_data.dat_scen #Scenario data
    sources_data = opt_data.dat_t_sources #Techno-eco sources data

    # Create the folder for input data if it does not exists
    data_used_folder = joinpath(resultsfolder,scd.Result_folder_name,"Data used","Scenario_$Nscen")
    if !isdir(data_used_folder)
        mkpath(data_used_folder)
    end

    if save_input_profiles
        CSV.write(joinpath(data_used_folder , "Flux_Profiles.csv"), matrix_to_dataframe(pd.Flux_Profile,"Flux"))
        CSV.write(joinpath(data_used_folder , "Price_Profiles.csv"), matrix_to_dataframe(pd.Price_Profile, "Price"))
        CSV.write(joinpath(data_used_folder , "CO2_profiles_regulated.csv"), matrix_to_dataframe(pd.CO2_profile_regulated, "CO2_reg"))
        CSV.write(joinpath(data_used_folder , "CO2_profiles_emitted.csv"), matrix_to_dataframe(pd.CO2_profile_emitted,"CO2_em"))

        # For 1D vector, use a simpler DataFrame
        df_renewable = DataFrame(t = 1:length(pd.Renewable_criterion_profile),
                             value = pd.Renewable_criterion_profile)
        CSV.write(joinpath(data_used_folder , "Renewable_criterion_profiles.csv"), df_renewable)
    end

    if save_input_technoeco
        n_units = length(Name_selected_units)
        df = DataFrame()
        
        for f in fieldnames(typeof(td)) # Fill in the techno-eco data columns and use the field name as column name
            values = getfield(td, f)
            # Only include 1D vectors matching number of units
            if isa(values, AbstractVector) && length(values) == n_units
                df[!, Symbol(f)] = values
            end
        end

        # Insert Name selected unit first and rename it to "Unit"
        insertcols!(df, 1, :Unit => Name_selected_units)

        CSV.write(joinpath(data_used_folder, "Technoeco_data.csv"), df)

        #Repeat for the techno-eco data sources of the file exists
        if !isnothing(sources_data)
            dfs = DataFrame()
            for f in fieldnames(typeof(sources_data)) # Fill in the techno-eco data columns and use the field name as column name
                values = getfield(sources_data, f)
                # Only include 1D vectors matching number of units
                if isa(values, AbstractVector) && length(values) == n_units
                    dfs[!, Symbol(f)] = values
                end
            end
            # Insert Name selected unit first and rename it to "Unit"
            insertcols!(dfs, 1, :Unit => Name_selected_units)

            CSV.write(joinpath(data_used_folder, "Technoeco_data_sources.csv"), dfs)
        end
    end
end

end #Module end