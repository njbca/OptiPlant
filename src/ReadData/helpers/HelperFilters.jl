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
    indexes,
    corners
)
    unit_col = indexes.idx_t.units[2]           # Column index where unit names are stored
    data_start_row = corners.L1                 # First data row (after header)

    unit_names = matrix[data_start_row:end, unit_col]  # Extract unit names from matrix

    allowed_units = get(mapping, selected_key, String[])
    mapped_units = vcat(values(mapping)...)

    # Flag rows to keep (true = keep row)
    keep_flags = [!(u in mapped_units) || (u in allowed_units) for u in unit_names]

    # Calculate full list of row indices to keep
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end

"Filter by a pattern, optionally allowing exceptions."
function filter_matrix_by_pattern(
    matrix::AbstractMatrix,
    pattern::String,
    indexes,
    corners;
    allowed_exceptions::Vector{String}=String[]
)
    unit_col = indexes.idx_t.units[2]        # Column containing unit names
    data_start_row = corners.L1           # Start row of actual data

    unit_names = matrix[data_start_row:end, unit_col]
    allowed_set = Set(allowed_exceptions)

    # Flag rows to keep
    keep_flags = [!occursin(pattern, u) || (u in allowed_set) for u in unit_names]

    # Keep headers + filtered data rows
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end


"Exclude units that contain any user-defined substrings."

function filter_matrix_by_custom_exclude(
    matrix::AbstractMatrix,
    exclude_terms::Vector{String},
    indexes,
    corners
)
    unit_col = indexes.idx_t.units[2]       # Column with unit names
    data_start_row = corners.L1          # First row of actual data

    unit_names = matrix[data_start_row:end, unit_col]

    # Keep units that DO NOT match any exclude term
    keep_flags = [all(term -> term != u, exclude_terms) for u in unit_names]

    # Keep header rows + matching rows
    keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))

    return matrix[keep_rows, :]
end

function filter_matrix_by_electrolyser_type(
    matrix::AbstractMatrix,
    Electrolyser::String,
    indexes,
    corners;
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
            unit_col = indexes.idx_t.units[2]
            data_start_row = corners.L1
            unit_names = matrix[data_start_row:end, unit_col]

            # Inline "Mix" filtering logic
            keep_flags = [!(occursin("AEC", u) || occursin("SOEC", u)) || occursin("Mix", u) for u in unit_names]
            keep_rows = vcat(1:(data_start_row - 1), findall(keep_flags) .+ (data_start_row - 1))
            matrix = matrix[keep_rows, :]
        else
            matrix = filter_matrix_by_pattern(matrix, exclude_type, indexes, corners)
        end
    else
        error("Undefined electrolyser type: $electrolyser_type")
    end

    # Step 2: Filter based on heat integration
    if haskey(heat_int_exclusion_rules, heat_integration)
        matrix = filter_matrix_by_pattern(matrix, heat_int_exclusion_rules[heat_integration], indexes, corners)
    end

    return matrix
end


# --- Master function to apply all filters ---

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

    data_units_filtered = filter_matrix_by_mapping(Data_units, Fuel, fuel_map, indexes,corners)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, CO2_capture, co2_map,indexes,corners)
    data_units_filtered = filter_matrix_by_electrolyser_type(data_units_filtered, Electrolyser,indexes,corners)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, Water_supply, water_map, indexes,corners)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, H2_storage, storage_map,indexes,corners)
    data_units_filtered = filter_matrix_by_mapping(data_units_filtered, CSP_tech, csp_map,indexes,corners)
    data_units_filtered = filter_matrix_by_custom_exclude(data_units_filtered, Custom_exclude,indexes,corners)

    if ! isnothing(Data_sources)
        data_sources_filtered = filter_matrix_by_mapping(Data_sources, Fuel, fuel_map, indexes,corners)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, CO2_capture, co2_map,indexes,corners)
        data_sources_filtered = filter_matrix_by_electrolyser_type(data_sources_filtered, Electrolyser,indexes,corners)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, Water_supply, water_map,indexes,corners)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, H2_storage, storage_map,indexes,corners)
        data_sources_filtered = filter_matrix_by_mapping(data_sources_filtered, CSP_tech, csp_map,indexes,corners)
        data_sources_filtered = filter_matrix_by_custom_exclude(data_sources_filtered, Custom_exclude,indexes,corners)
    else
        data_sources_filtered = nothing
    end

    #Get the index of each selected unit in the techno-eco data units file
    return data_units_filtered, data_sources_filtered
end

#=
units = [
    "Biomass wood",
    "MeOH plant - biomass",
    "Sale of biochar - biofuel",
    "Biomass straw",
    "Biomass - Pyrolysis Unit",
    "Biofuel upgrading unit",
    "Sale of biochar DME",
    "Biomass bamboo 1",
    "Biomass bamboo 2",
    "Biomass wheat 1",
    "Biomass wheat 2",
    "Bamboo1-stage-SOEC (HI)",
    "Bamboo2-stage-SOEC (HI)",
    "Wheat1-stage-SOEC (HI)",
    "Wheat2-stage-SOEC (HI)",
    "NH3 plant + ASU - AEC (A)",
    "NH3 plant + ASU - Mix/SOEC (HI)",
    "H2 client",
    "H2 pipeline to end-user",
    "Desalination plant",
    "Waste water plant",
    "Drinking water",
    "Electrolysers AEC",
    "Electrolysers SOEC heat integrated (HI)",
    "Electrolysers SOEC (A)",
    "Electrolysers Mix 75AEC-25SOEC (HI)",
    "Electrolysers Mix 75AEC-25SOEC (A)",
    "Sale of oxygen",
    "Heat from district heating",
    "Heat sent to district heating",
    "Heat sent to other process",
    "H2 tank compressor",
    "H2 tank valve",
    "H2 tank",
    "H2 pipes compressor",
    "H2 pipes valve",
    "H2 buried pipes",
    "Solar fixed",
    "Solar tracking",
    "ON_SP198-HH100",
    "ON_SP198-HH150",
    "ON_SP237-HH100",
    "ON_SP237-HH150",
    "CSP Plant tower 50 MW",
    "CSP Plant tower 100 MW",
    "CSP Plant parabolic 50 MW",
    "CSP Plant parabolic 100 MW",
    "Charge TES",
    "Discharge TES",
    "TES ST 50 MW",
    "TES ST 100 MW",
    "TES PT 50 MW",
    "TES PT 100 MW",
    "CSP+TES",
    "Electricity from the grid",
    "Curtailment",
    "Charge batteries",
    "Discharge batteries",
    "Batteries"
]

# Create the 3-column matrix
matrix = [[units[i] string(i) string(i * 10)] for i in 1:length(units)]

# Convert to actual matrix
result = reduce(vcat, matrix)

indexes = (idx_t = (units = (1, 1),),)
corners = (L1 = 1,)

filtered = apply_all_unit_filters(result,indexes,corners;
    Fuel = "NH3",
    CO2_capture = "None",
    Electrolysers = "AEC_A",
    Water_supply = "Desalination plant",
    H2_storage = "H2 tank",
    CSP_tech = "Tower50",
    Custom_exclude = ["ON_SP198-HH100","ON_SP198-HH150"]  
)

=#