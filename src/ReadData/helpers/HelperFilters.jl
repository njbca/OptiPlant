include("../user_defined/Names.jl")

# Filters for profiles

function filter_profile(data, index, C0, selection_type)
    if isnothing(data) || isnothing(index)
        return data
    else
        all_values = data[index[1], index[2] + 1:end]
        selected = findall(x -> x == selection_type || x == "All", all_values)
        not_selected = setdiff(1:length(all_values), selected)
        return data[:, setdiff(1:size(data, 2), not_selected .+ C0)]
    end
end

# Identify the index of the plant units that are user-defined in the "Selected_unit" sheet

function get_selected_units_from_list(
    Data_selected_units,
    Data_units,
    scen,
    indexes,
    corners
)
    # Extract configuration list and all unit names
    configuration_list = Data_selected_units[corners.L0_s, corners.C0_s + 1:end]
    unit_names = Data_units[corners.L1:end, indexes.idx_t.units[2]]
    n_units = length(unit_names)

    # Find which configuration column to use
    config_idx = findfirst(==(scen.Configuration_scenario), configuration_list)

    if isnothing(config_idx)
        error("Configuration '$(scen.Configuration_scenario)' not found in configuration list.")
    end

    # Get selected units indexes
    selected_units = findall(==(1), Data_selected_units[(corners.L0_s + 1):end, corners.C0_s + config_idx])

    # Filter input data according to these selected units indexes
    return selected_units
end

function filter_by_units_from_list(Data_units, Data_sources, Selected_Unit, indexes, corners)
    # Compute row indices to keep (headers + selected units)
    keep_units = [1:(corners.L1 - 1); Selected_Unit .+ (corners.L1 - 1)]

    # Filter by rows
    Data_units_filtered = Data_units[keep_units, :]
    Data_sources_filtered = isnothing(Data_sources) ? nothing : Data_sources[keep_units, :]

    return Data_units_filtered, Data_sources_filtered
end

function filter_units_by_year_data(Data_units, Data_sources, scen, indexes, corners)
    # Identify parameter years from header row
    parameters_year = [isa(x, String) ? x : string(x)
                      for x in Data_units[indexes.idx_t.year[1], indexes.idx_t.year[2] + 1:end]]
    n_years = length(parameters_year)

    # Find years to keep
    selected_years = findall(x -> x == scen.Year || x == "All", parameters_year)
    not_selected_years = setdiff(1:n_years, selected_years)

    # Compute column indices to keep
    keep_years = setdiff(1:size(Data_units, 2), not_selected_years .+ corners.C0)

    # Filter by columns
    Data_units_filtered = Data_units[:, keep_years]
    Data_sources_filtered = isnothing(Data_sources) ? nothing : Data_sources[:, keep_years]

    # Extract selected unit names
    Name_selected_units = Data_units_filtered[corners.L1:end, indexes.idx_t.units[2]]

    return Data_units_filtered, Data_sources_filtered, Name_selected_units
end

# --- General filter functions for automatic unit filtering ---

"Filter a unit list based on a selected key and mapping dictionary."
function filter_matrix_by_mapping(
    matrix::AbstractMatrix,
    selected_key::String,
    mapping::Dict{String, Vector{String}},
    column_index,
    data_start_row
)

    column_values = matrix[data_start_row:end, column_index]  # Extract unit names from matrix

    allowed_values = get(mapping, selected_key, String[])
    mapped_values = vcat(values(mapping)...)

    # Flag rows to keep (true = keep row)
    keep_flags = [!(u in mapped_values) || (u in allowed_values) for u in column_values]

    # Calculate full list of row indices to keep
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end

"Filter by a pattern, optionally allowing exceptions."
function filter_matrix_by_pattern(
    matrix::AbstractMatrix,
    pattern::String,
    column_index,
    data_start_row;
    allowed_exceptions::Vector{String}=String[]
)

    column_values = matrix[data_start_row:end, column_index]
    allowed_set = Set(allowed_exceptions)

    # Flag rows to keep
    keep_flags = [!occursin(pattern, u) || (u in allowed_set) for u in column_values]

    # Keep headers + filtered data rows
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end

function filter_matrix_by_electrolyser_type(
    matrix::AbstractMatrix,
    Electrolyser::String,
    column_index,
    data_start_row;
    electrolyser_exclusion_rules::Dict = electrolyser_exclusion_rules,
    heat_integration_map::Dict = heat_integration_map,
    heat_int_exclusion_rules::Dict = heat_int_exclusion_rules,
    default_heat_integration::String = default_heat_integration
)
    # Parse electrolyser type and heat integration
    parts = split(Electrolyser, "_")
    electrolyser_type = parts[1]

    heat_integration = if length(parts) == 2
        get(heat_integration_map, parts[2], default_heat_integration)
    else
        println("Default: electrolyser not heat integrated with the fuel plant")
        default_heat_integration
    end

    # Step 1: Filter based on electrolyser type
    if haskey(electrolyser_exclusion_rules, electrolyser_type)
        exclude_type = electrolyser_exclusion_rules[electrolyser_type]

        if electrolyser_type == "Mix"
            column_values = matrix[data_start_row:end, column_index]

            # Inline "Mix" filtering logic
            keep_flags = [!(occursin("AEC", u) || occursin("SOEC", u)) || occursin("Mix", u) for u in column_values]
            keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))
            matrix = matrix[keep_rows, :]
        else
            matrix = filter_matrix_by_pattern(matrix, exclude_type, column_index, data_start_row)
        end
    else
        error("Undefined electrolyser type: $electrolyser_type")
    end

    # Step 2: Filter based on heat integration
    if haskey(heat_int_exclusion_rules, heat_integration)
        matrix = filter_matrix_by_pattern(matrix, heat_int_exclusion_rules[heat_integration], column_index, data_start_row)
    end

    return matrix
end

"Exclude values that contain any user-defined substrings."

function filter_matrix_by_custom_exclude(
    matrix::AbstractMatrix,
    exclude_terms::Vector{String},
    column_index,
    data_start_row
)
    column_values = matrix[data_start_row:end, column_index]

    # Keep values that DO NOT match any exclude term
    keep_flags = [all(term -> term != u, exclude_terms) for u in column_values]

    # Keep header rows + matching rows
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end

function filter_matrix_by_custom_include(
    matrix::AbstractMatrix,
    include_terms,
    column_index,
    data_start_row
)
    column_values = string.(matrix[data_start_row:end, column_index])

    #Convert into strings
    include_terms_str = collect(string.(include_terms))

    # Keep values that MATCH (exact equality) one of the include terms
    keep_flags = [any(term -> term == u, include_terms_str) for u in column_values]

    # Keep header rows + matching rows
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end


# --- Master function to apply all filters for the techno-economic file ---

"Apply all filters to a list of unit names using the selected configuration."
function filter_units_auto(Data_units, Data_sources, indexes,
    corners;
    Fuel::String,
    CO2_capture::String,
    Electrolyser::String,
    Water_supply::String,
    H2_storage::String,
    CSP_tech::String,
    Custom_exclude::Vector{String}=String[]
)
    column_index = indexes.idx_t.units[2]       # Column with unit names
    data_start_row = corners.L1                 # First data row (after header) 

    data_units_filtered = filter_matrix_by_mapping(Data_units, Fuel, fuel_map, column_index,data_start_row)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, CO2_capture, co2_map,column_index,data_start_row)
    data_units_filtered = filter_matrix_by_electrolyser_type(data_units_filtered, Electrolyser,column_index,data_start_row)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, Water_supply, water_map, column_index,data_start_row)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, H2_storage, storage_map,column_index,data_start_row)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, CSP_tech, csp_map,column_index,data_start_row)
    data_units_filtered = filter_matrix_by_custom_exclude(data_units_filtered, Custom_exclude,column_index,data_start_row)

    if ! isnothing(Data_sources)
        data_sources_filtered = filter_matrix_by_mapping(Data_sources, Fuel, fuel_map, column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, CO2_capture, co2_map,column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_electrolyser_type(data_sources_filtered, Electrolyser,column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, Water_supply, water_map,column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, H2_storage, storage_map,column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, CSP_tech, csp_map,column_index,data_start_row)
        data_sources_filtered = filter_matrix_by_custom_exclude(data_sources_filtered, Custom_exclude,column_index,data_start_row)
    else
        data_sources_filtered = nothing
    end

    #Get the index of each selected unit in the techno-eco data units file
    return data_units_filtered, data_sources_filtered
end

# --- Master function to apply all filters for the lcia file ---

"Apply all filters to a list of lcia parameters using the selected filters."
function filter_lcia_auto(Data_lcia, indexes,
    corners;
    Technology_to_keep::Vector{String}=String[],
    Phase_to_keep::Vector{String}=String[],
    Method_to_keep::Vector{String}=String[],
    Impact_categories_to_keep::Vector{String}=String[],
    Iam_model_to_keep::Vector{String}=String[],
    Iam_scenario_to_keep::Vector{String}=String[],
    Lcia_year_to_keep,
    Year_data,
    Lcia_tags_list
)

    # First data row (after header)    
    data_start_row = corners.L0_lcia + 1  

    # Identify column indices in the lcia table

    Lcia_parameters_name = Data_lcia[indexes.idx_lcia.corner[1], indexes.idx_lcia.corner[2]:end]

    get_col_index(name) = corners.C0_lcia - 1 + findfirst(x -> x == name, Lcia_parameters_name)

    C_technology = get_col_index(LCIAColumnNames.technology)
    C_phase = get_col_index(LCIAColumnNames.phase)
    C_method = get_col_index(LCIAColumnNames.method_family)
    C_impact_categories = get_col_index(LCIAColumnNames.impact_categories)
    C_iam_model = get_col_index(LCIAColumnNames.iam_model)
    C_iam_scenario = get_col_index(LCIAColumnNames.iam_scenario)
    C_lcia_year = get_col_index(LCIAColumnNames.year_lcia)
    

    data_lcia_filtered = filter_matrix_by_custom_include(Data_lcia, Method_to_keep, C_method, data_start_row)
    data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Iam_model_to_keep, C_iam_model, data_start_row)
    data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Iam_scenario_to_keep, C_iam_scenario, data_start_row)

    if Phase_to_keep[1] != "Keep_all"
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Phase_to_keep, C_phase, data_start_row)
    end

    if Impact_categories_to_keep[1] != "Keep_all"
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Impact_categories_to_keep, C_impact_categories, data_start_row)
    end

    if Lcia_year_to_keep[1] == "Same_as_technoeco"
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Year_data, C_lcia_year, data_start_row) 
    else
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Lcia_year_to_keep, C_lcia_year, data_start_row)
    end

    if Technology_to_keep[1] == "Same_as_technoeco"
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Lcia_tags_list, C_technology, data_start_row) 
    else
        data_lcia_filtered = filter_matrix_by_custom_include(data_lcia_filtered, Technology_to_keep, C_technology, data_start_row) 
    end
     
    return data_lcia_filtered
end