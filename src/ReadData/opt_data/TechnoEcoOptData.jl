module TechnoEcoOptData

include("../helpers/HelperFilters.jl")
include("../helpers/HelperFunctions.jl")


include("../user_defined/Names.jl")

export technoeco_opt_data,
      load_and_locate_techno_data,
      filter_units,
      apply_scenario_changes!,
      build_technoeco_opt_data,
      build_technoeco_sources_data,
      apply_scenario_options!


# Struct to hold all techno-economic parameters of the energy system units

struct technoeco_opt_data

  Used_Unit                      # Indicate if the unit is used in the energy system or not
  Capacity_units                 # Input data units for the capacities
  Output_units                   # Input data units for the output flows

  Demand                         # Output fuel demand

  #Balances
  H2_balance                     # H2 balance
  El_balance                     # El balance
  CSP_balance                    # CSP balance
  Heat_balance                   # Heat balance
  Process_heat_balance           # Process heat balance

  Heat_generated                 # Excess that can be recovered per unit
  Process_heat_generated         # Process heat that can be recovered per unit

  #Technical parameters
  Max_Cap                        # Maximum capacity that can be installed per element of the energy system
  Load_min                       # Minimum load of the unit
  Ramp_up                        # Ramp rate upward
  Ramp_down                      # Ramp rate downward

  #Efficiencies and production
  Sc_nom                         # Specific electrical consumption
  Prod_rate                      # Fuel production rate

  # Economics
  Invest                         # Investment cost
  FixOM                          # Fixed operation and maintenance costs
  VarOM                          # Variable operation and maintenance costs
  Fuel_Selling_fixed             # Selling price of the output fuel for each unit
  Fuel_Buying_fixed              # Fixed fuel buying price

  # Emissions and environmental impacts
  CO2_inf_reg                     # CO2 emitted from the infrastructure used for regulations
  CO2_proc_fixed_reg              # CO2 emitted from the process used for regulations

  # Financial parameters
  Annuity_factor                 # Check the Excel for detailed calculations

end

# ************ Import techno-economic data ********************

"""
    load_and_locate_techno_data(
        wb_techno,
        Available_sheets_techno,
        scen,
        key_terms_technoeco,
        key_terms_selected_units,
        key_terms_scenarios
    )

Loads and indexes all techno-economic and scenario-related datasets from the 
techno-economic workbook.  

This function reads unit definitions, reference datasets, unit selections, exclusions, 
and scenario definitions. It then locates relevant indexes using predefined key terms 
and extracts corner coordinates to structure data access in downstream processing.

# Arguments
- `wb_techno`: Workbook handle containing techno-economic data.
- `Available_sheets_techno`: List of available sheets (used for validation).
- `scen`: Scenario object that defines which input datasets (`Input_data`, `Input_ref`) to load.
- `key_terms_technoeco`: Dictionary of key terms for locating indexes in the techno-economic data.
- `key_terms_selected_units`: Key terms for identifying selected unit indexes.
- `key_terms_scenarios`: Key terms for identifying scenario definition indexes.

# Returns
A named tuple containing:
- `Data_units`: Techno-economic dataset of units (scenario-dependent).
- `Data_sources`: Reference dataset for technologies (scenario-dependent).
- `Data_selected_units`: Dataset of included technologies/units.
- `Data_excluded_units`: Dataset of excluded technologies/units.
- `Data_scenarios_def`: Scenario definition dataset.
- `indexes`: Sub-tuple of located index structures (`idx_t`, `idx_s`, `idx_ex`, `idx_sd`) with symbols corresponding to `key_terms` keys. 
    By writing i.e. indexes.idx_t.year you access the line and column of  "year"
- `corners`: Sub-tuple of corner coordinates for structured data access 
  (`L1`, `C0`, `L0_s`, `C0_s`, `L0_ex`, `C0_ex`, `L1_sd`, `C1_sd`).

# Notes
- `Data_units` and `Data_sources` are **scenario-dependent** and can vary across runs.
- Indexes are located using `locate_indexes`, which maps key terms to sheet coordinates.
- `get_corner_table` provides safe access to corner coordinates, returning `nothing` if absent.
"""


function load_and_locate_techno_data(
    wb_techno,
    Available_sheets_techno,
    scen,
    key_terms_technoeco,
    key_terms_selected_units,
    key_terms_scenarios
)

    # === Load relevant sheets from techno-economic workbook ===
    Data_units = read_xlsx_sheet(wb_techno, scen.Input_data, Available_sheets_techno ; warn = true) #Can be scenario dependent
    Data_sources = read_xlsx_sheet(wb_techno, scen.Input_ref, Available_sheets_techno) #"Can be scenario dependent"
    Data_selected_units = read_xlsx_sheet(wb_techno, SheetTags.selected_units, Available_sheets_techno)
    Data_excluded_units = read_xlsx_sheet(wb_techno, SheetTags.excluded_units, Available_sheets_techno)
    Data_scenarios_def = read_xlsx_sheet(wb_techno, SheetTags.scenario_definition, Available_sheets_techno; warn = true)

    # === Locate indexes in the techno-economic and scenario sheets based on key terms ===
    idx_t = locate_indexes(Data_units, key_terms_technoeco)
    idx_s = locate_indexes(Data_selected_units, key_terms_selected_units)
    idx_ex = locate_indexes(Data_excluded_units, key_terms_excluded_units)
    idx_sd = locate_indexes(Data_scenarios_def, key_terms_scenarios)

    # === Helper function to extract corner coordinates ===
    get_corner_table(idx, i; offset=0) = isnothing(idx.corner) ? nothing : idx.corner[i] + offset

    # === Return all relevant data, indexes, and their coordinates ===
    return (
        Data_units = Data_units,
        Data_sources = Data_sources,
        Data_selected_units = Data_selected_units,
        Data_excluded_units = Data_excluded_units,
        Data_scenarios_def = Data_scenarios_def,
        indexes = (
            idx_t = idx_t,
            idx_s = idx_s,
            idx_ex = idx_ex,
            idx_sd = idx_sd
        ),
        corners = (
            L1 = get_corner_table(idx_t, 1, offset=1),
            C0 = get_corner_table(idx_t, 2),
            L0_s = get_corner_table(idx_s, 1),
            C0_s = get_corner_table(idx_s, 2),
            L0_ex = get_corner_table(idx_ex,1),
            C0_ex = get_corner_table(idx_ex,2),
            L1_sd = get_corner_table(idx_sd, 1, offset=1),
            C1_sd = get_corner_table(idx_sd, 2),
  

        )
    )
end

# ****************** Filter the units used in the optimization ********************

"""
    filter_units(techno_scen_data, scen)

Filters techno-economic units based on selected units, exclusions, and scenario parameters.

This function processes the raw techno-economic datasets (`Data_units`, `Data_sources`) 
and applies filtering according to user-defined selections (`Data_selected_units`) if available. 
If no explicit selection is provided, an automatic filter is applied based on scenario 
attributes such as `Fuel`, `Electrolyser`, `CO2_capture`, `Water_supply`, `H2_storage`, and `CSP_tech`. 
The function also considers excluded units and filters by scenario year data.

# Arguments
- `techno_scen_data`: Scenario-specific techno-economic data including datasets, indexes, and corners.
- `scen`: Scenario object defining filtering attributes and year data.

# Returns
- `Data_units_filtered`: Filtered techno-economic dataset for units.
- `Data_sources_filtered`: Filtered reference dataset.
- `Name_selected_units`: Names of units retained after filtering.
- `U`: Total number of retained units.

# Notes
- Uses either user-defined selection from the `selected_units` sheet or an automatic filter based on scenario attributes.
- Year-specific filtering ensures that only units relevant to the scenario year are retained.
- Provides feedback in the console indicating which filtering method is applied.
"""


function filter_units(
    techno_scen_data,
    scen
)
    
    #Unpack data

    Data_units = techno_scen_data.Data_units
    Data_sources = techno_scen_data.Data_sources
    Data_selected_units = techno_scen_data.Data_selected_units
    Data_excluded_units = techno_scen_data.Data_excluded_units

    indexes = techno_scen_data.indexes
    corners = techno_scen_data.corners

    if ! isnothing(Data_selected_units)
        println("Units are filtered according to the $(SheetTags.selected_units) sheet")
        selected_units = get_selected_units_from_list(Data_selected_units, Data_units, scen, indexes, corners)
        Data_units_filtered, Data_sources_filtered = filter_by_units_from_list(Data_units, Data_sources, selected_units, indexes, corners)
    
    else
        println("Automatic units filter is being used: make sure that user_defined/Names.jl are corresponding to the input excel file")
        Data_units_filtered, Data_sources_filtered = filter_units_auto(Data_units, Data_sources, indexes,corners;
            Fuel = scen.Fuel,
            CO2_capture = scen.CO2_capture,
            Electrolyser = scen.Electrolyser,
            Water_supply = scen.Water_supply,
            H2_storage = scen.H2_storage,
            CSP_tech = scen.CSP_tech,
            Custom_exclude = isnothing(Data_excluded_units) ? String[] : [isa(x, String) ? x : string(x) for x in Data_excluded_units[(corners.L0_ex + 1):end, corners.C0_ex]] 
        )
    end

    Data_units_filtered, Data_sources_filtered, Name_selected_units = filter_units_by_year_data(
        Data_units_filtered, Data_sources_filtered, scen, indexes, corners)
    U = length(Name_selected_units)

    return Data_units_filtered, Data_sources_filtered, Name_selected_units, U
end

# Define scenario data and change the original data file depending on the scenario------------------------------------

"""
    apply_scenario_changes!(
        Data_units,
        Name_selected_units,
        techno_scen_data,
        scen
    )

Applies scenario-specific changes directly to the `Data_units` dataset in-place.

This function updates the techno-economic unit dataset based on a scenario definition. 
It identifies the relevant rows and columns corresponding to the selected units and 
parameters for the current scenario, then replaces base-case values with scenario-specific 
values. Changes can be conditional on the year or applicable to all years.

# Arguments
- `Data_units`: Techno-economic dataset of units (modified in-place).
- `Name_selected_units`: Names of units retained after filtering.
- `techno_scen_data`: Scenario-specific metadata including `Data_scenarios_def`, indexes, and corners.
- `scen`: Scenario object specifying the scenario name and year (`Scenario`, `Year`).

# Behavior
- Constructs a `Name_Year` mapping to locate parameter columns efficiently.
- Identifies scenario rows where changes are relevant for the current scenario.
- Uses dictionaries for fast lookup of unit names and parameter-year combinations.
- Updates the corresponding entries in `Data_units` in-place; no new array is returned.

# Notes
- Handles parameters applicable to all years (`"All"`) or specific years.
- Skips changes if either the unit or parameter is not found in the filtered dataset.
- Relies on `ScenchangeTags` for column identification in the scenario definition sheet.
"""

function apply_scenario_changes!(
    Data_units,                 
    Name_selected_units,
    techno_scen_data,
    scen
)
    # Unpack data
    Data_scenarios_def = techno_scen_data.Data_scenarios_def
    indexes = techno_scen_data.indexes
    corners = techno_scen_data.corners

    # Extract base case data parameters
    Parameters_name = Data_units[indexes.idx_t.parameters[1], indexes.idx_t.parameters[2]+1:end]
    Parameters_year = [isa(x, String) ? x : string(x) for x in Data_units[indexes.idx_t.year[1], indexes.idx_t.year[2]+1:end]]
    nPar = length(Parameters_name)

    # Precompute concatenated name-year identifiers
    Year_str = string(scen.Year)
    Name_Year = [Parameters_year[i] == "All" ?
        Parameters_name[i] * Year_str :
        Parameters_name[i] * Parameters_year[i]
        for i in 1:nPar]

    # Identify column indices in the scenario definition table
    Scenario_def_parameters = Data_scenarios_def[corners.L1_sd - 1, corners.C1_sd:end]
    get_col_index(name) = corners.C1_sd - 1 + findfirst(x -> x == name, Scenario_def_parameters)

    C_unit_changed = get_col_index(ScenchangeTags.c_unit_changed)
    C_parameter_changed = get_col_index(ScenchangeTags.c_parameter_changed)
    C_year_new_value = get_col_index(ScenchangeTags.c_year_new_value)
    C_new_value = get_col_index(ScenchangeTags.c_new_value)
    C_reference = get_col_index(ScenchangeTags.c_reference)
    C_scen_name = get_col_index(ScenchangeTags.c_scen_name)

    # Identify scenario rows
    Scenario_def_name = Data_scenarios_def[corners.L1_sd:end, C_scen_name]
    Reference_scenario = Data_scenarios_def[corners.L1_sd:end, C_reference]
    scen_name = scen.Scenario
    ref_scen = Reference_scenario[findfirst(x -> x == scen_name, Scenario_def_name)]
    Current_scenario = findall(x -> x == ref_scen || x == scen_name, Scenario_def_name)
    nCurscen = length(Current_scenario)

    # Preallocate outputs
    Unit_changed = Vector{String}(undef, nCurscen)
    Parameter_changed = Vector{String}(undef, nCurscen)
    Parameters_year_changed = Vector{String}(undef, nCurscen)
    New_value = zeros(nCurscen)
    C_to_change = zeros(Int, nCurscen)
    L_to_change = zeros(Int, nCurscen)

    # Fill values
    for i in 1:nCurscen
        row = corners.L1_sd + Current_scenario[i] - 1
        unit = Data_scenarios_def[row, C_unit_changed]
        param = Data_scenarios_def[row, C_parameter_changed]
        year_val = string(Data_scenarios_def[row, C_year_new_value])
        new_val = Data_scenarios_def[row, C_new_value]

        Unit_changed[i] = unit
        Parameter_changed[i] = param
        New_value[i] = new_val
        Parameters_year_changed[i] = year_val == "All" ? param * Year_str : param * year_val
    end

    # Create dictionaries for fast lookup
    name_year_to_col = Dict(ny => j for (j, ny) in enumerate(Name_Year))
    unit_to_row = Dict(unit => u for (u, unit) in enumerate(Name_selected_units))

    # Apply changes
    for i in 1:nCurscen
        C_to_change[i] = get(name_year_to_col, Parameters_year_changed[i], 0)
        L_to_change[i] = get(unit_to_row, Unit_changed[i], 0)

        if L_to_change[i] != 0 && C_to_change[i] != 0
            Data_units[corners.L1 - 1 + L_to_change[i], corners.C0 + C_to_change[i]] = New_value[i]
        end
    end
end

# ****************** Prepare techno-economic data for the optimization model ******************
#Get the techno-eco parameter by comparing the name to the one in the excel file: they have to be the same !

"""
    build_technoeco_opt_data(Data_units, techno_scen_data)
    build_technoeco_sources_data(Data_sources, techno_scen_data)

Builds a techno-economic data structure (`technoeco_opt_data`) for optimization from 
either a unit dataset (`Data_units`) or a sources dataset (`Data_sources`).

Both functions extract parameters describing technology units — such as capacity, 
balances, emissions, and costs — and map them into a structured format for the 
optimization model. The difference lies in the type of input handled:

- `build_technoeco_opt_data`: extracts primarily **numeric** values from `Data_units`.
- `build_technoeco_sources_data`: extracts primarily **string** values from `Data_sources`.

# Arguments
- `Data_units` / `Data_sources`: Techno-economic dataset containing unit definitions 
  and parameters (numeric or string depending on the variant).
- `techno_scen_data`: Scenario-specific metadata providing indexing (`indexes`, `corners`).

# Returns
A `technoeco_opt_data` object containing:
- Unit usage, capacity units, output units
- Demand and balance constraints (`H₂`, electricity, CSP, heat, process heat)
- Generated outputs (heat, process heat)
- Capacity and operational constraints (`Max_Cap`, `Load_min`, `Ramp_up`, `Ramp_down`)
- Scaling parameters and production rates
- Investment and O&M costs (`Invest`, `FixOM`, `VarOM`)
- Fuel trading parameters (`Fuel_Selling_fixed`, `Fuel_Buying_fixed`)
- CO₂ data (`CO2_inf_em`, `CO2_proc_fixed`)
- Financial parameters (`Annuity_factor`)

# Notes
- Helper functions (`get_technoeco_data`, `get_technoeco_data_warning`, 
  `get_technoeco_data_string`, etc.) ensure consistent parsing and apply defaults 
  when values are missing.
"""

function build_technoeco_opt_data(Data_units, techno_scen_data)

    #Unpack data
    indexes = techno_scen_data.indexes
    corners = techno_scen_data.corners

    # Extract parameter names
    Parameters_name = Data_units[indexes.idx_t.parameters[1], indexes.idx_t.parameters[2]+1:end]

    # Generic wrapper
    get_param(param; as_string=false, warn=false) = get_data_from_table(
        Data_units, param, Parameters_name, corners.L1, corners.C0;
        as_string=as_string, warn=warn
    )

    names = TechnoEcoColumnNames

    return technoeco_opt_data(
        get_param(names.used_unit, warn=true),                # Used_Unit
        get_param(names.capacity_units, as_string=true, warn=true),  # Capacity units
        get_param(names.output_units, as_string=true, warn=true),    # Output flows units

        get_param(names.demand, warn=true),                  # Demand

        get_param(names.h2_balance, warn=true),             # H2_balance
        get_param(names.el_balance, warn=true),             # El_balance
        get_param(names.csp_balance),                       # CSP_balance
        get_param(names.heat_balance, warn=true),           # Heat_balance
        get_param(names.process_heat_balance),             # Process_heat_balance

        get_param(names.heat_generated, warn=true),         # Heat_generated
        get_param(names.process_heat_generated),           # Process_heat_generated

        get_param(names.max_cap, warn=true),               # Max_Cap
        get_param(names.load_min, warn=true),              # Load_min
        get_param(names.ramp_up, warn=true),               # Ramp_up
        get_param(names.ramp_down, warn=true),             # Ramp_down

        get_param(names.sc_nom, warn=true),                # Sc_nom
        get_param(names.prod_rate, warn=true),             # Prod_rate

        get_param(names.invest, warn=true),                # Invest
        get_param(names.fixom, warn=true),                 # FixOM
        get_param(names.varom, warn=true),                 # VarOM
        get_param(names.fuel_selling_fixed, warn=true),    # Fuel_Selling_fixed
        get_param(names.fuel_buying_fixed),               # Fuel_Buying_fixed

        get_param(names.co2_inf_reg),                      # CO2_inf_em
        get_param(names.co2_proc_fixed_reg),              # CO2_proc_fixed

        get_param(names.annuity_factor, warn=true)        # Annuity_factor
    )

end

function build_technoeco_sources_data(Data_sources, techno_scen_data)

    #Unpack data
    indexes = techno_scen_data.indexes
    corners = techno_scen_data.corners

    # Extract parameter names
    Parameters_name = Data_sources[indexes.idx_t.parameters[1], indexes.idx_t.parameters[2]+1:end]

    # Wrapper for string extraction
    get_param_string(param) = get_data_from_table(
        Data_sources, param, Parameters_name, corners.L1, corners.C0;
        as_string=true, warn=false
    )

    names = TechnoEcoColumnNames

    return technoeco_opt_data(
        get_param_string(names.used_unit),                 # Used_Unit
        get_param_string(names.capacity_units),           # Capacity units
        get_param_string(names.output_units),             # Output flows units

        get_param_string(names.demand),                   # Demand

        get_param_string(names.h2_balance),              # H2_balance
        get_param_string(names.el_balance),              # El_balance
        get_param_string(names.csp_balance),             # CSP_balance
        get_param_string(names.heat_balance),            # Heat_balance
        get_param_string(names.process_heat_balance),    # Process_heat_balance

        get_param_string(names.heat_generated),          # Heat_generated
        get_param_string(names.process_heat_generated),  # Process_heat_generated

        get_param_string(names.max_cap),                 # Max_Cap
        get_param_string(names.load_min),                # Load_min
        get_param_string(names.ramp_up),                 # Ramp_up
        get_param_string(names.ramp_down),               # Ramp_down

        get_param_string(names.sc_nom),                  # Sc_nom
        get_param_string(names.prod_rate),               # Prod_rate

        get_param_string(names.invest),                  # Invest
        get_param_string(names.fixom),                   # FixOM
        get_param_string(names.varom),                   # VarOM
        get_param_string(names.fuel_selling_fixed),      # Fuel_Selling_fixed
        get_param_string(names.fuel_buying_fixed),       # Fuel_Buying_fixed

        get_param_string(names.co2_inf_reg),             # CO2_inf_em
        get_param_string(names.co2_proc_fixed_reg),      # CO2_proc_fixed

        get_param_string(names.annuity_factor)           # Annuity_factor
    )
end

#------8 - Overwrite techno-economic optimization data for some specific scenario features-------------------

"""
    apply_scenario_options!(dat_sub, dat_t, dat_p, scen)

Applies scenario-specific option overrides to techno-economic and price profile data in-place.

This function updates the optimization data structures based on scenario options, 
including fixed sales of heat, oxygen, process heat, biochar, and CH₄, as well as 
hourly electricity and heat sales. It also enforces non-negative price constraints if 
specified. All changes are applied directly to the provided data structures.

# Arguments
- `dat_sub`: Subset data object containing indices for units, products, and sales.
- `dat_t`: Techno-economic data object (`technoeco_opt_data`) to be updated in-place.
- `dat_p`: Profile data object containing price profiles to be modified in-place.
- `scen`: Scenario object specifying option flags:
    - `Option_fixed_heat_sale`, `Option_fixed_oxygen_sale`, `Option_fixed_process_heat_sale`,
      `Option_fixed_biochar_sale`, `Option_fixed_CH4_sale`
    - `Option_no_negative_prices`
    - `Option_hourly_elec_sale`, `Option_hourly_heat_sale`
    - `T` (total number of time steps)

# Behavior
- Sets `Fuel_Selling_fixed` entries to zero for any disabled fixed sale options.
- Sets negative prices to zero if `Option_no_negative_prices` is true.
- Sets hourly price profiles to zero for disabled hourly sale options.

# Notes
- All modifications are applied in-place; no new objects are returned.
- Assumes `dat_sub` indices correctly map to the corresponding entries in `dat_t` and `dat_p`.
"""

function apply_scenario_options!(
    dat_sub,
    dat_t,
    dat_p,
    scen
)
    #Unpack data
    T = scen.T
    if scen.Option_fixed_heat_sale == false && dat_sub.Heat_sell[1] != 0
        for i = 1:dat_sub.nHs
            dat_t.Fuel_Selling_fixed[dat_sub.Heat_sell[i]] = 0
        end
    end

    if scen.Option_fixed_oxygen_sale == false && dat_sub.O2_sell[1] != 0
        for i = 1:dat_sub.nO2s
            dat_t.Fuel_Selling_fixed[dat_sub.O2_sell[i]] = 0
        end
    end

    if scen.Option_fixed_process_heat_sale == false && dat_sub.Process_heat_sell[1] != 0
        for i = 1:dat_sub.nphs
            dat_t.Fuel_Selling_fixed[dat_sub.Process_heat_sell[i]] = 0
        end
    end

    if scen.Option_fixed_biochar_sale == false && dat_sub.Biochar_sell[1] != 0
        for i = 1:dat_sub.nbios
            dat_t.Fuel_Selling_fixed[dat_sub.Biochar_sell[i]] = 0
        end
    end

    if scen.Option_fixed_CH4_sale == false && dat_sub.CH4_sell[1] != 0
        for i = 1:dat_sub.nCH4
            dat_t.Fuel_Selling_fixed[dat_sub.CH4_sell[i]] = 0
        end
    end

    for i = 1:dat_sub.nSubp, t = 1:T
        if scen.Option_no_negative_prices == true
            if dat_p.Price_Profile[i, t] < 0
                dat_p.Price_Profile[i, t] = 0
            end
        end
    end

    if scen.Option_hourly_elec_sale == false && dat_sub.Grid_sell_p[1] > 0
        for i in dat_sub.Grid_sell_p, t = 1:T
            dat_p.Price_Profile[i, t] = 0
        end
    end

    if scen.Option_hourly_heat_sale == false && dat_sub.Heat_sell_p[1] > 0
        for i in dat_sub.Heat_sell_p, t = 1:T
            dat_p.Price_Profile[i, t] = 0
        end
    end
end

end #Module