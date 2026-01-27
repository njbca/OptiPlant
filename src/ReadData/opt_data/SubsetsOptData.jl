module SubsetsOptData

include("../helpers/HelperFunctions.jl")
include("../user_defined/Names.jl")

export subsets_opt_data, build_subsets_opt_data

# Struct to hold all relevant subsets

struct subsets_opt_data
    # Subsets related to techno-economics
    Reactants
    R
    MainFuel
    PU
    RPU ; nRPU
    Grid_in
    Heat_in
    Grid_out
    Heat_out
    Products
    nProd
    MinD ; nMinD
    Tanks ; nST
    Stor_in
    Stor_out
    O2_sell; nO2s
    Biochar_sell; nbios
    Heat_sell; nHs
    Process_heat_sell; nphs
    CH4_sell ; nCH4
    Hourly_heat_buy; nHb
    Grid_sell; nGs
    Grid_buy; nGb
    PWL; nPWL
    NotPWL

    # Main bubsets related to flux profiles
    Heat_sell_p
    Heat_buy_p
    Grid_sell_p
    Grid_buy_p
    RPU_p
    Grid_excess; nGe
    Grid_deficit; nGd
    Heat_excess; nHe
    Heat_deficit; nHd

    # Subsets related to CO2 profiles
    Grid_CO2_emitted_p; nGCO2em
    Grid_CO2_regulated_p; nGCO2reg

    # Subsets related to lcia hourly data
    Impact_categories_p ; nImpactCat

    # Number of subsets per profile type
    nSubf #Flux
    nSubp #Price
    nSubC_em #CO2 emitted
    nSubC_reg #CO2 regulated
    nSubLcia_profile #Hourly lcia indicators

end

"""
    build_subsets_opt_data(Data_units, techno_scen_data, profile_data, profile_data_filtered, U)

Builds subset structures from techno-economic and profile data for optimization.

This function extracts, categorizes, and indexes subsets of units, products, storages, fluxes, 
prices, and CO₂ profiles. These subsets define how different system components (units, 
profiles, and interactions) are grouped and connected for the optimization model.

# Arguments
- `Data_units`: Raw techno-economic dataset (unit definitions and attributes).
- `techno_scen_data`: Scenario-specific techno-economic metadata (corners, indexes).
- `profile_data`: Metadata for available profile subsets (price, flux, CO₂).
- `profile_data_filtered`: Filtered profile arrays used in the optimization.
- `U`: Total number of units.

# Returns
A `subsets_opt_data` object containing:
- **Reactants and main units**: `Reactants`, `R`, `MainFuel`, `PU` (power units), `RPU` (renewable power units with profiles).
- **Energy exchanges**: Subsets for grid and heat in/out, excess/deficit handling.
- **Products and storage**: `Products`, `nProd`, `MinD`, `nMinD`, `Tanks`, `Stor_in`, `Stor_out`.
- **Market interactions**: Subsets for selling/buying O₂, biochar, heat, process heat, CH₄, grid, etc.
- **Electrolyzer piecewise linear function**: `PWL`, `nPWL`, `NotPWL`.
- **Profile subsets**: Links between units and corresponding flux, price, and CO₂ profiles.
- **Counts of subsets**: `nSubf`, `nSubp`, `nSubC_em`, `nSubC_reg`.

# Notes
- Reactants are identified by matching techno-economic subsets with reactant subsets.
- Renewable power units (`RPU`) must have matching flux profiles; missing matches trigger an error message.
- Supports flexible tagging system (`SubsetTags`) to define and identify subset categories.
"""


# Build all subsets and store in SubsetData struct
function build_subsets_opt_data(
    Data_units,
    techno_scen_data,
    profile_data,
    profile_data_filtered,
    U,
    dat_lcia
)
    # Unpack data
    Data_price_profile = profile_data_filtered.Data_price_profile
    Data_flux_profile = profile_data_filtered.Data_flux_profile
    Data_CO2_profile_reg = profile_data_filtered.Data_CO2_profile_reg
    Data_CO2_profile_em = profile_data_filtered.Data_CO2_profile_em
    Data_lcia_profile = profile_data_filtered.Data_lcia_profile

    L1 = techno_scen_data.corners.L1
    idx_t = techno_scen_data.indexes.idx_t
    idx_pr = profile_data.indexes.idx_pr
    idx_f = profile_data.indexes.idx_f
    idx_CO2_reg = profile_data.indexes.idx_CO2_reg
    idx_CO2_em = profile_data.indexes.idx_CO2_em
    idx_lcia_profile = profile_data.indexes.idx_lcia_profile

    # === Extract subsets from techno-economic and profile data ===
    Subsets, nSubsets = extract_subset_technoeco(Data_units, L1, idx_t.subsets)
    Subsets_2, nSubsets2 = extract_subset_technoeco(Data_units, L1, idx_t.subsets2)
    Subsets_reactants, nSubReac = extract_subset_technoeco(Data_units, L1, idx_t.subsetsreactant)

    Subsets_flux, nSubf = extract_subset_profiles(Data_flux_profile, idx_f.subsets)
    Subsets_price, nSubp = extract_subset_profiles(Data_price_profile, idx_pr.subsets)

    Subsets_CO2_reg, nSubC_reg = extract_subset_profiles(Data_CO2_profile_reg, idx_CO2_reg.subsets)
    Subsets_CO2_em, nSubC_em = extract_subset_profiles(Data_CO2_profile_em, idx_CO2_em.subsets)

    Subsets_lcia_profile, nSubLcia_profile = extract_subset_profiles(Data_lcia_profile, idx_lcia_profile.subsets)

    # === Impact categories profiles ===

    if !isnothing(dat_lcia)
        impact_categories_symbol = dat_lcia.impact_categories_symbol

        # Small function to sanitize impact categories names
        sanitize(s) = Symbol(replace(lowercase(string(s)), r"[^a-z0-9]+" => "_"))

        nImpactCat = length(impact_categories_symbol)
        Impact_categories_p = round.(Int, zeros(nImpactCat))

        for i = 1:nImpactCat, j = 1:nSubLcia_profile
            if sanitize(Subsets_lcia_profile[j]) == impact_categories_symbol[i]
                Impact_categories_p[i] = j
            end
        end
    else
        Impact_categories_p = 0 ; nImpactCat = 0

    end
   
    # === Reactant used to produce the main product (chemical reactions) ===
    Reactants = round.(Int, zeros(nSubReac))
    for i = 1:nSubsets, j = 1:nSubReac
        if Subsets[i] == Subsets_reactants[j]
            Reactants[j] = i
        end
    end
    filter!(x -> x != 0, Reactants)
    R = length(Reactants)

    # === Main fuel unit (e.g. Ammonia plant) ===
    MainFuel = findall(x -> occursin(SubsetTags.main_fuel, x), Subsets_2) #Tags can be modified in the Names.jl file

    # === Power unit that generates electricity ===
    PU = findall(x -> occursin(SubsetTags.power_unit, x), Subsets)

    # === Renewable power unit (profile dependent) ===
    RPU = findall(x -> occursin(SubsetTags.renewable_pu, x), Subsets)
    nRPU = length(RPU)
    RPU_p = round.(Int, zeros(nRPU))
    for u = 1:nRPU, j = 1:nSubf # This loop is to make sure that subset in renewable technology techno-economic data matches with profile data
        if occursin(Subsets_flux[j], Subsets[RPU[u]])
            RPU_p[u] = j
        end
    end
    # Give a message error when the profiles subsets and techno-economic data are not matching (RPU_p = 0)
    for u = 1:nRPU
        if RPU_p[u] == 0
            unit_names = Data_units[L1:end, idx_t.units[2]]
            @error("No profile available for $(unit_names[RPU[u]]) in the selected location: check that the techno-econmic and profiles subsets are matching or exclude the missing unit from the optimization")
        end
    end

    # === Public grid and district heating ===
    Grid_in = findall(x -> occursin(SubsetTags.grid_in, x), Subsets)
    Heat_in = findall(x -> occursin(SubsetTags.heat_in, x), Subsets)
    Grid_out = findall(x -> occursin(SubsetTags.grid_out, x), Subsets)
    Heat_out = findall(x -> occursin(SubsetTags.heat_out, x), Subsets)

    # === Product units and storage ===
    Products = findall(x -> occursin(SubsetTags.product, x), Subsets)
    nProd = length(Products)
    MinD = findall(x -> occursin(SubsetTags.min_demand, x), Subsets_2)
    nMinD = length(MinD)
    Tanks = findall(x -> x == SubsetTags.tank, Subsets)
    nST = length(Tanks)
    Stor_in = findall(x -> x == SubsetTags.stor_in, Subsets)
    Stor_out = findall(x -> x == SubsetTags.stor_out, Subsets)

    # === Option to sale/purchase of fuel ===
    O2_sell, nO2s = extract_from_subsets(Subsets_2, SubsetTags.o2_sell)
    Biochar_sell, nbios = extract_from_subsets(Subsets_2, SubsetTags.biochar_sell)
    Heat_sell, nHs = extract_from_subsets(Subsets_2, SubsetTags.heat_sell)
    Process_heat_sell, nphs = extract_from_subsets(Subsets_2, SubsetTags.process_heat_sell)
    CH4_sell, nCH4 = extract_from_subsets(Subsets_2, SubsetTags.ch4_sell)
    Hourly_heat_buy, nHb = extract_from_subsets(Subsets_2, SubsetTags.heat_buy)
    Grid_sell, nGs = extract_from_subsets(Subsets_2, SubsetTags.grid_sell)
    Grid_buy, nGb = extract_from_subsets(Subsets_2, SubsetTags.grid_buy)

    # === Piecewise linear function for electrolyzer specific consumption ===
    PWL, nPWL = extract_from_subsets(Subsets_2, SubsetTags.pwl)
    NotPWL = setdiff(1:U, PWL)

    # === Subsets related to price profiles ===
    Heat_sell_p = extract_from_subsets(Subsets_price, SubsetTags.heat_sell_p)[1]
    Heat_buy_p = extract_from_subsets(Subsets_price, SubsetTags.heat_buy_p)[1]
    Grid_sell_p = extract_from_subsets(Subsets_price, SubsetTags.grid_sell_p)[1]
    Grid_buy_p = extract_from_subsets(Subsets_price, SubsetTags.grid_buy_p)[1]

    # === Subsets related to flux profiles ===
    Grid_excess, nGe = extract_from_subsets(Subsets_flux, SubsetTags.grid_excess)
    Grid_deficit, nGd = extract_from_subsets(Subsets_flux, SubsetTags.grid_deficit)
    Heat_excess, nHe = extract_from_subsets(Subsets_flux, SubsetTags.heat_excess)
    Heat_deficit, nHd = extract_from_subsets(Subsets_flux, SubsetTags.heat_deficit)

    # === Subsets related to grid CO2 profiles ===
    Grid_CO2_emitted_p, nGCO2em = extract_from_subsets(Subsets_CO2_em, SubsetTags.grid_em)
    Grid_CO2_regulated_p, nGCO2reg = extract_from_subsets(Subsets_CO2_reg, SubsetTags.grid_reg)

    return subsets_opt_data(
        Reactants, R, MainFuel, PU, RPU, nRPU,
        Grid_in, Heat_in, Grid_out, Heat_out,
        Products, nProd, MinD, nMinD,
        Tanks, nST, Stor_in, Stor_out,
        O2_sell, nO2s, Biochar_sell, nbios,
        CH4_sell, nCH4,
        Heat_sell, nHs, Process_heat_sell, nphs,
        Hourly_heat_buy, nHb, Grid_sell, nGs, Grid_buy, nGb,
        PWL, nPWL, NotPWL,
        Heat_sell_p, Heat_buy_p, Grid_sell_p, Grid_buy_p, RPU_p,
        Grid_excess, nGe, Grid_deficit, nGd,
        Heat_excess, nHe, Heat_deficit, nHd,
        Grid_CO2_emitted_p, nGCO2em, Grid_CO2_regulated_p, nGCO2reg,
        Impact_categories_p , nImpactCat,
        nSubf, nSubp, nSubC_em, nSubC_reg, nSubLcia_profile
    )
end



end