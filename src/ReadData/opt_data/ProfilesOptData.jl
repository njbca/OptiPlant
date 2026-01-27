module ProfilesOptData

include("../helpers/HelperFilters.jl")
include("../helpers/HelperFunctions.jl")

include("../user_defined/Names.jl")

export profiles_opt_data,
load_and_locate_profile_data,
filter_all_profile_data,
build_profiles_opt_data

# Struct to store all profile matrices
struct profiles_opt_data

    Flux_Profile
    Price_Profile
    CO2_profile_regulated
    CO2_profile_emitted
    Renewable_criterion_profile
    Lcia_profile

end

# ************ Import profile data ********************

"""
    load_and_locate_profile_data(wb_profile, Available_sheets_profiles, key_terms_profiles)

Loads and indexes all profile-related datasets (flux, price, CO₂, renewable criterion) 
from the profile workbook.  

This function reads the relevant profile sheets, locates their indexes based on 
provided key terms, and extracts corner coordinates for structured access. 
It returns both the raw data arrays and the associated metadata required 
for building optimization inputs.

# Arguments
- `wb_profile`: Workbook handle containing the profile data sheets.
- `Available_sheets_profiles`: List of available sheets (used for validation).
- `key_terms_profiles`: Dictionary of key terms for locating indexes in each profile sheet.

# Returns
A named tuple containing:
- `Data_flux_profile`: Raw flux profile data.
- `Data_price_profile`: Raw price profile data.
- `Data_CO2_profile_reg`: CO₂ profiles used for regulation.
- `Data_CO2_profile_em`: CO₂ profiles not used for regulation.
- `Data_rencrit_profile`: Renewable criterion profiles.
- `indexes`: Sub-tuple with located index structures (`idx_f`, `idx_pr`, `idx_CO2_reg`, `idx_CO2_em`, `idx_rencrit`).
- `corners`: Sub-tuple with corner coordinates (`L0_*`, `C0_*`) for aligning data slices.

# Notes
- Each index is located using `locate_indexes`, which maps key terms to row/column positions.
- If a profile sheet or index is missing, the corresponding corner values may be `nothing`.
"""


function load_and_locate_profile_data(
    wb_profile,
    Available_sheets_profiles,
    key_terms_profiles
)

    # === Load relevant profile sheets ===
    Data_flux_profile = read_xlsx_sheet(wb_profile, SheetTags.flux, Available_sheets_profiles; warn=true)
    Data_price_profile = read_xlsx_sheet(wb_profile, SheetTags.price, Available_sheets_profiles; warn=true)
    Data_CO2_profile_reg = read_xlsx_sheet(wb_profile, SheetTags.co2_regulated, Available_sheets_profiles)
    Data_CO2_profile_em = read_xlsx_sheet(wb_profile, SheetTags.co2_emitted, Available_sheets_profiles)
    Data_rencrit_profile = read_xlsx_sheet(wb_profile, SheetTags.rencrit, Available_sheets_profiles)
    Data_lcia_profile = read_xlsx_sheet(wb_profile, SheetTags.lcia_hourly, Available_sheets_profiles; warn=true)


    # === Locate indexes in the profile sheets based on key terms ===
    idx_f = locate_indexes(Data_flux_profile, key_terms_profiles, true)
    idx_pr = locate_indexes(Data_price_profile, key_terms_profiles, true)
    idx_CO2_reg = locate_indexes(Data_CO2_profile_reg, key_terms_profiles, true)
    idx_CO2_em = locate_indexes(Data_CO2_profile_em, key_terms_profiles, true)
    idx_rencrit = locate_indexes(Data_rencrit_profile, key_terms_profiles, true)
    idx_lcia_profile = locate_indexes(Data_lcia_profile, key_terms_profiles, true)

    # === Helper function to extract corner coordinates ===
    get_corner_table(idx, i) = isnothing(idx.corner) ? nothing : idx.corner[i]

    # === Return all profile-related data, indexes, and their coordinates ===
    return (
        Data_flux_profile = Data_flux_profile,
        Data_price_profile = Data_price_profile,
        Data_CO2_profile_reg = Data_CO2_profile_reg,
        Data_CO2_profile_em = Data_CO2_profile_em,
        Data_rencrit_profile = Data_rencrit_profile,
        Data_lcia_profile = Data_lcia_profile,
        indexes = (
            idx_f = idx_f,
            idx_pr = idx_pr,
            idx_CO2_reg = idx_CO2_reg,
            idx_CO2_em = idx_CO2_em,
            idx_rencrit = idx_rencrit,
            idx_lcia_profile = idx_lcia_profile
        ),
        corners = (
            L0_f = get_corner_table(idx_f, 1),
            C0_f = get_corner_table(idx_f, 2),
            L0_pr = get_corner_table(idx_pr, 1),
            C0_pr = get_corner_table(idx_pr, 2),
            L0_CO2_reg = get_corner_table(idx_CO2_reg, 1),
            C0_CO2_reg = get_corner_table(idx_CO2_reg, 2),
            L0_CO2_em = get_corner_table(idx_CO2_em, 1),
            C0_CO2_em = get_corner_table(idx_CO2_em, 2),
            L0_rencrit = get_corner_table(idx_rencrit, 1),
            C0_rencrit = get_corner_table(idx_rencrit, 2),
            L0_lcia_profile = get_corner_table(idx_lcia_profile, 1),
            C0_lcia_profile = get_corner_table(idx_lcia_profile, 2)
        )
    )
end

# ************ Filter profile data ********************

"""
    filter_all_profile_data(profile_data, scen)

Filters raw profile datasets (flux, price, CO₂, renewable criterion) based on scenario parameters.  

This function applies sequential filters to the loaded profile data to select only the 
entries relevant to a given scenario. Profiles are first filtered by location, then by 
additional scenario attributes such as time series type, CO₂ counting method, and 
renewable criterion.

# Arguments
- `profile_data`: Output from `load_and_locate_profile_data`, containing raw profile arrays, 
  indexes, and corner coordinates.
- `scen`: Scenario object with attributes controlling the filtering process 
  (`Location`, `Power_TS`, `CO2_count_method_reg`, `CO2_count_method_em`, `Current_rencrit`).

# Returns
A named tuple containing the filtered profile arrays:
- `Data_flux_profile`
- `Data_price_profile`
- `Data_CO2_profile_reg`
- `Data_CO2_profile_em`
- `Data_rencrit_profile`

# Notes
- Filtering is done using `filter_profile`, applied to both location and scenario-specific dimensions.
- Ensures that only scenario-relevant slices of the profile datasets are passed downstream 
  for building optimization inputs.
"""

function filter_all_profile_data(
    profile_data,  # output from load_and_locate_profile_data
    scen           # scenario object
)
    # Unpack data
    Data_flux_profile = profile_data.Data_flux_profile
    Data_price_profile = profile_data.Data_price_profile
    Data_CO2_profile_reg = profile_data.Data_CO2_profile_reg
    Data_CO2_profile_em = profile_data.Data_CO2_profile_em
    Data_rencrit_profile = profile_data.Data_rencrit_profile
    Data_lcia_profile = profile_data.Data_lcia_profile

    indexes = profile_data.indexes
    corners = profile_data.corners

    # === Filter by location ===
    Data_flux_profile_filtered = filter_profile(Data_flux_profile, indexes.idx_f.locations, corners.C0_f, scen.Location)
    Data_price_profile_filtered = filter_profile(Data_price_profile, indexes.idx_pr.locations, corners.C0_pr, scen.Location)
    Data_CO2_profile_reg_filtered = filter_profile(Data_CO2_profile_reg, indexes.idx_CO2_reg.locations, corners.C0_CO2_reg, scen.Location)
    Data_CO2_profile_em_filtered = filter_profile(Data_CO2_profile_em, indexes.idx_CO2_em.locations, corners.C0_CO2_em, scen.Location)
    Data_rencrit_profile_filtered = filter_profile(Data_rencrit_profile, indexes.idx_rencrit.locations, corners.C0_rencrit, scen.Location)
    Data_lcia_profile_filtered = filter_profile(Data_lcia_profile, indexes.idx_lcia_profile.locations, corners.C0_lcia_profile, scen.Location)

    # === Additional filters ===
    Data_flux_profile_filtered = filter_profile(Data_flux_profile_filtered, indexes.idx_f.timeseries, corners.C0_f, scen.Power_TS)
    Data_CO2_profile_reg_filtered = filter_profile(Data_CO2_profile_reg_filtered, indexes.idx_CO2_reg.countmethod, corners.C0_CO2_reg, scen.CO2_count_method_reg)
    Data_CO2_profile_em_filtered = filter_profile(Data_CO2_profile_em_filtered, indexes.idx_CO2_em.countmethod, corners.C0_CO2_em, scen.CO2_count_method_em)
    Data_rencrit_profile_filtered = filter_profile(Data_rencrit_profile_filtered, indexes.idx_rencrit.subsets, corners.C0_rencrit, scen.Current_rencrit)

    return (
        Data_flux_profile = Data_flux_profile_filtered,
        Data_price_profile = Data_price_profile_filtered,
        Data_CO2_profile_reg = Data_CO2_profile_reg_filtered,
        Data_CO2_profile_em = Data_CO2_profile_em_filtered,
        Data_rencrit_profile = Data_rencrit_profile_filtered,
        Data_lcia_profile = Data_lcia_profile_filtered
    )
end

# *************** Prepare profile data for optimization ***************************

"""
    build_profiles_opt_data(profile_data_filtered, profile_data, dat_sub, scen)

Builds structured profile matrices required for optimization from raw input data and scenario parameters.

This function extracts and organizes time-dependent profiles (flux, price, CO₂ emissions, and renewable criteria)
from the filtered input datasets, based on subcategory definitions and scenario time settings. It aligns raw profile
data with the model's indexing scheme (`corners`) and produces matrices sized according to the number of subcategories
(`dat_sub`) and the scenario horizon (`T`).

# Arguments
- `profile_data_filtered`: Filtered data structure containing raw profile arrays
  (`Data_flux_profile`, `Data_price_profile`, `Data_CO2_profile_reg`, `Data_CO2_profile_em`, `Data_rencrit_profile`).
- `profile_data`: Data structure containing metadata about profile array indexing (`corners`).
- `dat_sub`: Object with the number of subcategories used for each type of profile
  (`nSubf`, `nSubp`, `nSubC_reg`, `nSubC_em`).
- `scen`: Scenario object containing time mapping (`Time`), time horizon (`T`), and renewable criterion selection (`Current_rencrit`).

# Returns
A `profiles_opt_data` object containing:
- `Flux_Profile` (`nSubf x T`): Matrix of flux profiles per subcategory.
- `Price_Profile` (`nSubp x T`): Matrix of price profiles per subcategory.
- `CO2_profile_regulated` (`nSubC_reg x T`): Matrix of CO₂ emissions accounted for regulation.
- `CO2_profile_emitted` (`nSubC_em x T`): Matrix of CO₂ emissions not used for regulation.
- `Renewable_criterion_profile` (`T`): Vector of renewable criterion values across time.

# Notes
- The function dynamically extracts the relevant slices of each dataset using offset values from `corners`
  and aligns them with the scenario's time index.
- If `scen.Current_rencrit == "None"`, the renewable criterion profile defaults to all ones.
"""

# Build profile matrices from input data arrays and parameters
function build_profiles_opt_data(
    profile_data_filtered,
    profile_data,
    dat_sub,
    scen
)
    # Unpack data
    Data_flux_profile = profile_data_filtered.Data_flux_profile
    Data_price_profile = profile_data_filtered.Data_price_profile
    Data_CO2_profile_reg = profile_data_filtered.Data_CO2_profile_reg
    Data_CO2_profile_em = profile_data_filtered.Data_CO2_profile_em
    Data_rencrit_profile = profile_data_filtered.Data_rencrit_profile
    Data_lcia_profile = profile_data_filtered.Data_lcia_profile

    Time = scen.Time
    T = scen.T

    corners = profile_data.corners

    #--------------------------------------------------------
    # Flux profiles
    Flux_Profile = zeros(dat_sub.nSubf, T)
    for i = 1:dat_sub.nSubf, t = 1:T
        Flux_Profile[i, t] = Data_flux_profile[corners.L0_f + Time[t], corners.C0_f + i]
    end

    #--------------------------------------------------------
    # Price profiles
    Price_Profile = zeros(dat_sub.nSubp, T)
    for i = 1:dat_sub.nSubp, t = 1:T
        Price_Profile[i, t] = Data_price_profile[corners.L0_pr + Time[t], corners.C0_pr + i]
    end

    #--------------------------------------------------------
    # CO2 Profiles: the one accounted for regulation
    CO2_profile_regulated = zeros(dat_sub.nSubC_reg, T)
    for i = 1:dat_sub.nSubC_reg, t = 1:T
        CO2_profile_regulated[i, t] = Data_CO2_profile_reg[corners.L0_CO2_reg + Time[t], corners.C0_CO2_reg + i]
    end

    #--------------------------------------------------------
    # CO2 profile: not used for regulation
    CO2_profile_emitted = zeros(dat_sub.nSubC_em, T)
    for i = 1:dat_sub.nSubC_em, t = 1:T
        CO2_profile_emitted[i, t] = Data_CO2_profile_em[corners.L0_CO2_em + Time[t], corners.C0_CO2_em + i]
    end

    #--------------------------------------------------------
    # Renewable criterion profile
    Renewable_criterion_profile = ones(T)
    if scen.Current_rencrit != "None"
        for t = 1:T
            Renewable_criterion_profile[t] = Data_rencrit_profile[corners.L0_rencrit + Time[t], corners.C0_rencrit + 1]
        end
    end

    #--------------------------------------------------------
    #Hourly lcia profiles (all impact categories instead of just CO2)
    Lcia_profile = zeros(dat_sub.nSubLcia_profile,T)
    for i = 1:dat_sub.nSubLcia_profile, t = 1:T
        Lcia_profile[i, t] = Data_lcia_profile[corners.L0_lcia_profile + Time[t], corners.C0_lcia_profile + i]
    end

    return profiles_opt_data(
        Flux_Profile,
        Price_Profile,
        CO2_profile_regulated,
        CO2_profile_emitted,
        Renewable_criterion_profile,
        Lcia_profile
    )
end

end # module
