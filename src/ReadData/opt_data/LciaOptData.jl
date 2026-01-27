module LciaOptData

include("../helpers/HelperFunctions.jl")
include("../helpers/HelperFilters.jl")
include("../user_defined/Names.jl")

using DataFrames

export lcia_opt_data, ImpactPhases, load_and_locate_lcia_data, filter_lcia_data, build_lcia_opt_data

mutable struct ImpactPhases
    inf::Vector{Float64}
    use::Vector{Float64}
    disp::Vector{Float64}
    ImpactPhases() = new(Float64[], Float64[], Float64[])
end

# Struct to hold all lcia parameters
mutable struct lcia_opt_data
    impact_categories_symbol :: Vector{Symbol}
    scores ::Dict{Symbol, ImpactPhases}
end

# **************** Import lcia data ********************

function load_and_locate_lcia_data(
    wb_lcia,
    Available_sheets_lcia,
    key_terms_lcia
)

    # === Load relevant profile sheets ===
    Data_lcia = read_xlsx_sheet(wb_lcia, SheetTags.lciadata, Available_sheets_lcia)
    Data_lcia_filters = read_xlsx_sheet(wb_lcia, SheetTags.lciafilters, Available_sheets_lcia)

    # === Locate indexes in the lcia sheets based on key terms ===
    idx_lcia = locate_indexes(Data_lcia, key_terms_lcia)
    idx_lcia_filters = locate_indexes(Data_lcia_filters, key_terms_lcia_filters)

    # === Helper function to extract corner coordinates ===
    get_corner_table(idx, i; offset=0) = isnothing(idx.corner) ? nothing : idx.corner[i] + offset

    # === Return all lcia-related data, indexes, and their coordinates ===
    return (
        Data_lcia = Data_lcia,
        Data_lcia_filters = Data_lcia_filters,
        indexes = (
            idx_lcia = idx_lcia,
            idx_lcia_filters = idx_lcia_filters
        ),
        corners = (
            L0_lcia = get_corner_table(idx_lcia, 1),
            C0_lcia = get_corner_table(idx_lcia, 2),
            L0_lcia_filters = get_corner_table(idx_lcia_filters, 1),
            C0_lcia_filters = get_corner_table(idx_lcia_filters, 2),
        )
    )
end

# ************** Filter the lcia data ******************

function filter_lcia_data(
    Data_units, # Use the filtered Data_units as input instead of the "original" Data_units contained in techno_scen_data
    techno_scen_data,
    lcia_data,
    scen
)

# Unpack data

Data_lcia = lcia_data.Data_lcia
Data_lcia_filters = lcia_data.Data_lcia_filters

# Get the year data from the techno-economic file
Year_data = [scen.Year]
# Get the list of lcia tags from the techno-economic file
Lcia_tags_list = Data_units[techno_scen_data.corners.L1:end, techno_scen_data.indexes.idx_t.lcia_tag[2]]
println("Lcia_tags_list: $Lcia_tags_list")

# Get the list of filtering parameters from the excel file
Lciafilters_parameters_name = Data_lcia_filters[lcia_data.indexes.idx_lcia_filters.corner[1], 
                                     lcia_data.indexes.idx_lcia_filters.corner[2]:end]

println("Lciafilterparameters:$Lciafilters_parameters_name")

# Get lcia parameters from the excel table
get_lcia_filters_param(param; as_string=true, warn=false) = get_data_from_table(
    Data_lcia_filters, param, Lciafilters_parameters_name, 
    lcia_data.corners.L0_lcia_filters+1, lcia_data.corners.C0_lcia_filters; offset=-1,
    as_string=as_string, warn=warn
    )

names = LCIAFilterColumnNames

Technology_to_keep = get_lcia_filters_param(names.technology_filter; warn=true)
Phase_to_keep = get_lcia_filters_param(names.phase_filter; warn=true)
Method_to_keep = get_lcia_filters_param(names.method_family_filter; warn=true)
Impact_categories_to_keep = get_lcia_filters_param(names.impact_categories_filter; warn=true)
Iam_model_to_keep = get_lcia_filters_param(names.iam_model_filter; warn=true)
Iam_scenario_to_keep = get_lcia_filters_param(names.iam_scenario; warn=true)
Lcia_year_to_keep = get_lcia_filters_param(names.year_lcia_filter; as_string=false, warn=true)

Data_lcia_filtered = filter_lcia_auto(Data_lcia, lcia_data.indexes,
    lcia_data.corners;
    Technology_to_keep = Technology_to_keep,
    Phase_to_keep = Phase_to_keep,
    Method_to_keep = Method_to_keep,
    Impact_categories_to_keep = Impact_categories_to_keep,
    Iam_model_to_keep = Iam_model_to_keep,
    Iam_scenario_to_keep = Iam_scenario_to_keep,
    Lcia_year_to_keep = Lcia_year_to_keep,
    Year_data = Year_data,
    Lcia_tags_list = Lcia_tags_list
)

#Data_lcia_filtered = filter_matrix(Data_lcia,4,"ecoinvent-cutoff-3.11")

return Data_lcia_filtered

end

# Build the lcia data to be ready for the optimization model

# Sanitize name into a Symbol
sanitize(s) = Symbol(replace(lowercase(string(s)), r"[^a-z0-9]+" => "_"))

function build_lcia_opt_data(Data_lcia_filtered, lcia_data, Data_units_filtered, techno_scen_data, U)
    Data_lcia = lcia_data.Data_lcia

    # Extract headers and tags
    Lcia_parameters_name = Data_lcia[lcia_data.indexes.idx_lcia.corner[1], 
                                     lcia_data.indexes.idx_lcia.corner[2]:end]
    Lcia_tags_list = Data_units_filtered[techno_scen_data.corners.L1:end, 
                                         techno_scen_data.indexes.idx_t.lcia_tag[2]]

    # Helper to pull a column from the table
    get_lcia_param(param; as_string=true, warn=false) = get_data_from_table(
        Data_lcia_filtered, param, Lcia_parameters_name, 
        lcia_data.corners.L0_lcia, lcia_data.corners.C0_lcia; offset=-1,
        as_string=as_string, warn=warn
    )

    names = LCIAColumnNames
    Technology       = get_lcia_param(names.technology; warn=true)
    Impact_categories = get_lcia_param(names.impact_categories; warn=true)
    Phase            = get_lcia_param(names.phase; warn=true)
    Score            = get_lcia_param(names.score; as_string=false, warn=true)

    lcia_scores = Dict{Symbol, ImpactPhases}()

    for r in eachindex(Impact_categories)
        cat   = sanitize(Impact_categories[r])
        phase = get(lcia_phase_map, Phase[r], nothing)
        u     = findfirst(==(Technology[r]), Lcia_tags_list)
        isnothing(u) && continue

        # Initialize category storage, default value is 0
        if !haskey(lcia_scores, cat)
            lcia_scores[cat] = ImpactPhases()
            lcia_scores[cat].inf  = fill(0.0, U)
            lcia_scores[cat].use  = fill(0.0, U)
            lcia_scores[cat].disp = fill(0.0, U)
        end

        getfield(lcia_scores[cat], phase)[u] = Score[r]
    end
    return lcia_opt_data(unique(sanitize.(Impact_categories)), lcia_scores)
end

end #Module