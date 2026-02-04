#************************* Excel sheet names **********************

SheetTags = (
    selected_units = "Selected_units",
    excluded_units = "Excluded_units",
    scenario_definition = "Scenarios_definition",    
    flux = "Flux",
    price = "Price",
    co2_regulated = "CO2_regulated",
    co2_emitted = "CO2_emitted",
    rencrit = "Renewable_criterion",
    lcia_hourly = "Lcia_hourly",
    lciadata = "Lcia_results",
    lciafilters = "Lcia_filters"
)

#****************Terms used to locate the data within the excel sheets*****************

# Left is the variable name in julia script (do not change) and right the name in the excel file
key_terms_technoeco = Dict(
    "subsets" => "Subsets", 
    "subsets2" => "Subsets_2",
    "subsetsreactant" => "Produced from",
    "units" => "Type of units",
    "lcia_tag" => "Lcia technology tag",
    "parameters" => "Parameters-->",
    "year" => "Year-->",
    "corner" => "Line/Column index"
)

key_terms_selected_units = Dict(
    "corner" => "Configuration"
)

key_terms_excluded_units = Dict(
    "corner" => "Excluded units name"
)

key_terms_scenarios = Dict(
    "corner" => "Reference scenario"
)

key_terms_profiles = Dict(
    "locations" => "Locations",
    "subsets" => "Subsets",
    "corner" => "Index",
    "timeseries" => "Profile time series",
    "countmethod" => "Counting_method",
    "impactcategoriesprofile" => "Impact_categories"
)

key_terms_lcia = Dict(
    "corner" => "Technology",
)

key_terms_lcia_filters = Dict(
    "corner" => "Filter_categories",
)

#************************** Scenario names ****************************

ScenarioTags = (
    scenario_number            = "Scenario number",
    scenario_name              = "Scenario name",
    scenario                   = "Scenario",
    year_data                  = "Year data",
    profile_name               = "Profile name",
    profile_folder_name        = "Profile folder name",
    location                   = "Location",
    fuel                       = "Fuel",
    electrolyser               = "Electrolyser",
    co2_capture                = "CO2 capture",
    csp_tech                   = "CSP tech",
    water_supply               = "Water supply",
    h2_storage                 = "H2 storage",
    power_ts                   = "Profile time series",
    simulation_hours           = "Simulation hours",
    co2_count_method_reg       = "Hourly CO2 count method regulation",
    co2_count_method_em        = "Hourly CO2 count method emission",
    co2_tax_wttop              = "CO2taxWTTop",
    co2_tax_wttup              = "CO2taxWTTup",
    co2_wttop_threshold        = "CO2treshWTTop",
    renewable_criterion        = "Renewable criterion",
    criterion_application      = "Criterion application",
    lcia_filename              = "Lcia data filename",
    result_folder_name         = "Result folder name",
    input_data_sheet           = "Input data sheet",
    input_references_sheet     = "Input references sheet",
    option_max_capacity        = "Max capacity",
    option_ramping             = "Ramping",
    option_no_negative_prices  = "No negative elec price",
    option_hourly_elec_sale    = "Hourly electricity sale",
    option_connection_limit    = "Connection limit",
    option_fixed_oxygen_sale   = "Fixed oxygen sale",
    option_fixed_heat_sale     = "Fixed heat sale",
    option_fixed_process_heat_sale = "Fixed process heat sale",
    option_fixed_biochar_sale  = "Fixed biochar sale",
    option_fixed_CH4_sale      = "Fixed CH4 sale",
    option_hourly_heat_sale    = "Hourly heat sale",
    write_sold_products        = "Sold products",
    write_fuel_cost            = "Fuel cost",
    write_flows                = "Flows"
)

#*************************** LCIA data column names  ******************

LCIAColumnNames = (
    technology = "Technology",
    phase = "Phase",
    functional_unit = "Functional unit",
    method_family = "Method family",
    impact_categories = "Impact category",
    impact_categories_description = "Impact category description",
    score = "Value",
    unit = "Impact category unit",
    iam_model = "IAM Model",
    iam_scenario = "Scenario",
    year_lcia = "Year"
)

#**************************** LCIA filters column names ***********************

LCIAFilterColumnNames = (
    technology_filter = "Technology",
    phase_filter = "Phase",
    method_family_filter = "Method family",
    impact_categories_filter = "Impact category",
    iam_model_filter = "IAM Model",
    iam_scenario = "Scenario",
    year_lcia_filter = "Year"
)

#**************************** LCIA phase map *************************************

lcia_phase_map = Dict(
    "Construction"    => :inf, # inf stand for "infrastructure"
    "Operation"      => :use,
    "Disposal" => :disp,
)

#*************************** Techno-economic column names  ******************

TechnoEcoColumnNames = (
    used_unit = "Used (1 or 0)",                                 # Used_Unit
    capacity_units = "Capacity units",                           # Capacity units
    output_units = "Output units",                               # Units of the output flows  
    
    demand = "Yearly demand (output)",                          # Demand

    h2_balance = "H2 balance",                                   # H2_balance
    el_balance = "El balance",                                   # El_balance
    csp_balance = "CSP balance",                                 # CSP_balance
    heat_balance = "Heat balance",                               # Heat_balance
    process_heat_balance = "Process heat balance",               # Process_heat_balance

    heat_generated = "Heat generated (kWh/output)",              # Heat_generated
    process_heat_generated = "Process heat generated (kWh/output)",  # Process_heat_generated

    max_cap = "Max Capacity",                                    # Max_Cap
    load_min = "Load min (% of max capacity)",                   # Load_min
    ramp_up = "Ramp up (% of capacity /h)",                      # Ramp_up
    ramp_down = "Ramp down (% of capacity /h)",                  # Ramp_down

    sc_nom = "Electrical consumption (kWh/output)",              # Sc_nom
    prod_rate = "Fuel production rate (kg output/kg input)",     # Prod_rate

    invest = "Investment (EUR/Capacity installed)",              # Invest
    fixom = "Fixed cost (EUR/Capacity installed/y)",             # FixOM
    varom = "Variable cost (EUR/output)",                        # VarOM
    fuel_selling_fixed = "Fuel selling price (EUR/output)",      # Fuel_Selling_fixed
    fuel_buying_fixed = "Fuel buying price (EUR/output)",        # Fuel_Buying_fixed

    co2_inf_reg = "CO2e infrastructure regulated (kg CO2e/Capacity/y)",     # CO2 of building infrastructure used for regulations
    co2_proc_fixed_reg = "CO2e process regulated (kg CO2e/output)",            # Constant process emissions used for regulation
    
    annuity_factor = "Annuity factor",                            # Annuity_factor
    lifetime = "Lifetime (years)"                               # Lifetime
)

#************************* Subsets names **********************

SubsetTags = (
    # Techno-economic file subsets
    main_fuel           = "MainFuel",
    power_unit          = "PU",
    renewable_pu        = "RPU",
    grid_in             = "Grid_in",
    heat_in             = "Heat_in",
    grid_out            = "Grid_out",
    heat_out            = "Heat_out",
    product             = "Product",
    min_demand          = "Min_demand",
    tank                = "Tank",
    stor_in             = "Stor_in",
    stor_out            = "Stor_out",
    #Used for option in the techno-eco file
    o2_sell             = "O2_sell",
    biochar_sell        = "Biochar_sell",
    heat_sell           = "Heat_sell",
    process_heat_sell   = "Process_heat_sell",
    ch4_sell            = "CH4_sell",
    heat_buy            = "Heat_buy",
    grid_sell           = "Grid_sell",
    grid_buy            = "Grid_buy",

    # Piecewise linear
    pwl                 = "PWL",

    # Price profiles
    heat_sell_p         = "Heat_sell",
    heat_buy_p          = "Heat_buy",
    grid_sell_p         = "Grid_sell",
    grid_buy_p          = "Grid_buy",

    # Flux profiles
    grid_excess         = "Grid_excess",
    grid_deficit        = "Grid_deficit",
    heat_excess         = "Heat_excess",
    heat_deficit        = "Heat_deficit",

    # Grid CO2 profiles
    grid_em             = "Grid_CO2_emitted",
    grid_reg            = "Grid_CO2_regulated",
)


#*****************************Change data based on scenarios**************************

ScenchangeTags = (
    c_unit_changed = "Type of units for change",
    c_parameter_changed = "Parameter changed",
    c_year_new_value = "Year new value",
    c_new_value = "New value",
    c_reference = "Reference scenario",
    c_scen_name = "Scenario name definition"
)


#*************************** Definition of the automatic filter terms**********************

# --- Mappings for automatic unit filters ---

# Scenario name in i.e. ScenarioToRun => Unit name in i.e. Data_base_case

csp_map = Dict(
    "Tower50" => ["CSP Plant tower 50 MW", "TES ST 50 MW","Charge TES","Discharge TES","CSP+TES"],
    "Tower100" => ["CSP Plant tower 100 MW", "TES ST 100 MW","Charge TES","Discharge TES","CSP+TES"],
    "Parabolic50" => ["CSP Plant parabolic 50 MW", "TES PT 50 MW","Charge TES","Discharge TES","CSP+TES"],
    "Parabolic100" => ["CSP Plant parabolic 100 MW", "TES PT 100 MW","Charge TES","Discharge TES","CSP+TES"]
)

water_map = Dict(
    "DP" => ["Desalination plant"],
    "WWP" => ["Waste water plant"],
    "DW" => ["Drinking water"]
)

storage_map = Dict(
    "Tank" => ["H2 tank compressor", "H2 tank valve", "H2 tank"],
    "Underground pipes" => ["H2 pipes compressor", "H2 pipes valve", "H2 buried pipes"]
)

fuel_map = Dict(
    "CH4" => ["Biogas3","CH4 plant"],
    "MeOH B1" => ["Biogas1","Membrane upgrading","MeOH plant - biogas"],
    "MeOH B2" => ["Biogas2", "MeOH plant - biogasdirect",],
    "MeOH CO2" => ["MeOH plant - CO2", "CO2 capture DAC", "CO2 capture PS"],
    "Bio-e-MeOH" => ["Biomass wood", "MeOH plant - biomass"],
    "Refined-PO" => ["Sale of biochar - biofuel", "Biomass straw", "Biomass - Pyrolysis Unit", "Biofuel upgrading unit"],
    "DME B1" => ["Sale of biochar DME", "Biomass bamboo 1", "Bamboo1-stage-SOEC (HI)"],
    "DME B2" => ["Sale of biochar DME", "Biomass bamboo 2", "Bamboo2-stage-SOEC (HI)"],
    "DME W1" => ["Sale of biochar DME", "Biomass wheat 1", "Wheat1-stage-SOEC (HI)"],
    "DME W2" => ["Sale of biochar DME", "Biomass wheat 2", "Wheat2-stage-SOEC (HI)"],
    "NH3" => ["NH3 plant + ASU - AEC (A)", "NH3 plant + ASU - Mix/SOEC (HI)"],
    "H2" => ["H2 client"]
)

co2_map = Dict(
    "DAC" => ["CO2 capture DAC"],
    "PS"  => ["CO2 capture PS"]
)

# Heat integration mapping (when the unit name contains...)
heat_integration_map = Dict(
    "HI" => "(HI)",   # heat integrated
    "A"  => "(A)"     # autonomous (not integrated)
)

# Default if no suffix provided
default_heat_integration = "(A)"

# Electrolyser exclusion rules when the name contains...
electrolyser_exclusion_rules = Dict(
    "AEC"  => "SOEC",
    "SOEC" => "AEC",
    "Mix"  => "Mix"   # special handling
)

# Which heat integration tags to filter out depending on choice
heat_int_exclusion_rules = Dict(
    "(HI)" => "(A)",
    "(A)"  => "(HI)"
)

