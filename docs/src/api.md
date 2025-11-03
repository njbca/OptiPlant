# API Reference

This page provides detailed documentation for OptiPlant.jl functions, modules, and data structures.

## Main Functions

### `run_optimization_scenarios`

Runs multiple optimization scenarios sequentially.

```julia
run_optimization_scenarios(
    datafoldername::String,
    techno_eco_filename::String,
    scenario_set::String,
    solver::String,
    scenarios_to_run;
    model::String = "LP",
    N_pareto_points::Int = 10,
    interior_points::Int = 2,
    objective1::String = "costs",
    objective2::String = "emissions_CO2e_regulated",
    profiles_filename::String = "Check_techno_eco",
    lcia_filename::String = "Check_techno_eco",
    results_currency::String = "EUR",
    results_currency_multiplier::Float64 = 1.0,
    default_results_cost_scale = "M",
    default_results_capacity_units = "t or MW or MWh",
    default_results_production_units = "kt or GWh",
    save_input_technoeco::Bool = true,
    save_input_profiles::Bool = true   
)
```

**Arguments:**
- `datafoldername`: Name of the data folder containing input files
- `techno_eco_filename`: Excel file with techno-economic parameters
- `scenario_set`: Sheet name containing scenarios to run
- `solver`: Optimization solver ("HiGHS" or "Gurobi")
- `scenarios_to_run`: Array of scenario numbers to execute

**Keyword Arguments:**
- `model`: Optimization model type ("LP" or "LP_2obj")
- `N_pareto_points`: Number of points for Pareto front (multi-objective only)
- `interior_points`: Interior points for Pareto analysis
- `objective1`, `objective2`: Objective functions for multi-objective optimization
- `profiles_filename`: Custom profiles file (optional)
- `lcia_filename`: Life cycle impact assessment data file
- `results_currency`: Currency for results output
- `results_currency_multiplier`: Conversion factor for currency
- `save_input_*`: Whether to save input data with results

**Returns:**
Results are saved to CSV files in the results folder. No direct return value.

**Example:**
```julia
using OptiPlantPtX

scenarios = [1, 2, 3]
run_optimization_scenarios(
    "Full_model",
    "Input_data_example", 
    "ScenariosToRun",
    "HiGHS",
    scenarios
)
```

### `run_optimization_scenarios_parallel`

Runs multiple optimization scenarios in parallel using distributed computing.

```julia
run_optimization_scenarios_parallel(
    datafoldername::String,
    techno_eco_filename::String,
    scenario_set::String,
    solver::String,
    scenarios_to_run;
    # Same keyword arguments as sequential version
)
```

**Arguments:** Same as `run_optimization_scenarios`

**Performance Note:** Requires multiple CPU cores and uses `Distributed.jl` for parallel execution. Recommended for large scenario sets (>10 scenarios).

**Example:**
```julia
using Distributed
addprocs(4)  # Add 4 worker processes

@everywhere using OptiPlantPtX

scenarios = 1:20  # 20 scenarios
run_optimization_scenarios_parallel(
    "Full_model",
    "Multi_scenario_data",
    "ScenariosToRun", 
    "HiGHS",
    scenarios
)
```

### `run_single_scenario`

Convenience function for running a single optimization scenario.

```julia
run_single_scenario(
    datafoldername::String,
    techno_eco_filename::String,
    scenario_number::Int;
    solver::String = "HiGHS"
)
```

**Arguments:**
- `datafoldername`: Data folder name
- `techno_eco_filename`: Input data Excel file
- `scenario_number`: Specific scenario to run
- `solver`: Optimization solver

**Example:**
```julia
run_single_scenario("Full_model", "Input_data_example", 1)
```

## Data Structures

### Configuration Parameters

Key configuration parameters used throughout the system:

#### Solver Configuration
```julia
# Supported solvers
Solver = "HiGHS"    # Open source linear programming solver
Solver = "Gurobi"   # Commercial solver (requires license)
```

#### Time Configuration
```julia
TMstart::Int        # Start hour for simulation
TMend::Int         # End hour for simulation  
Tbegin::Int        # Hours when plant can operate at 0% initially
Tfinish::Int       # Final simulation hour (max 8760)
```

#### Economic Configuration
```julia
Currency_factor::Float64 = 1.0  # Currency conversion (default EUR 2019)
```

### Input Data Structure

OptiPlant expects specific Excel file structures:

#### Techno-Economic Data (`Data_base_case` sheet)
| Column | Description | Units | Type |
|--------|-------------|-------|------|
| Type of units | Unit identifier | - | String |
| Investment | Capital cost | EUR/capacity | Float |
| Fixed O&M | Annual fixed costs | EUR/capacity/year | Float |
| Variable O&M | Variable operating costs | EUR/output | Float |
| Electrical consumption | Power requirement | kWh/output | Float |
| Load min | Minimum load factor | % of capacity | Float |
| Max Capacity | Maximum installable size | MW or t/h | Float |

#### Scenario Configuration (`ScenariosToRun` sheet)
| Column | Description | Example | Type |
|--------|-------------|---------|------|
| Scenario | Scenario number | 1 | Int |
| Location | Geographic location | Denmark | String |
| Fuel | Output fuel type | Hydrogen | String |
| Year data | Analysis year | 2019 | Int |
| Profile name | Time series identifier | DK1_2019 | String |
| Electrolyser | Technology type | PEM | String |

#### Profile Data (CSV format)
```csv
Hour,Wind_offshore,Wind_onshore,Solar_PV,Electricity_price
1,0.45,0.32,0.0,45.2
2,0.52,0.38,0.0,43.8
...
8760,0.41,0.35,0.15,42.1
```

**Column Requirements:**
- `Hour`: Sequential hour number (1-8760)
- Renewable columns: Capacity factors (0-1)
- `Electricity_price`: EUR/MWh

## Result Data Structure

### Main Results CSV Output

Each scenario produces a CSV file with the following structure:

| Column | Description | Units |
|--------|-------------|-------|
| Scenario | Scenario identifier | - |
| Type of unit | Technology type | - |
| Location | Geographic location | - |
| Fuel | Output fuel | - |
| Installed capacity | Optimal capacity | MW, t/h, MWh, t |
| Total investment | Capital cost | M€ |
| Annualised investment | Annual capital cost | M€/year |
| Fixed O&M | Annual fixed costs | M€/year |
| Variable O&M | Annual variable costs | M€/year |
| Fuel cost | Annual fuel costs | M€/year |
| Production | Annual output | kton or GWh |
| Load average | Capacity factor | % |
| Full load hours | Operating hours | hours/year |
| Production cost | Levelized cost | €/kg or €/MWh |

### Hourly Results (Optional)

When `Write_flows = true`, detailed hourly operation data is saved:

| Column | Description | Units |
|--------|-------------|-------|
| Hour | Time step | 1-8760 |
| Unit_X | Production for unit X | kg/h or kW |
| Capacity_X | Installed capacity | MW or t/h |
| Load_factor_X | Operating level | % of capacity |

## Modules

### ReadData Module

Handles data import and processing:

#### `ScenariosOptData`
- Reads scenario definitions from Excel
- Parses configuration parameters
- Validates scenario consistency

#### `TechnoEcoOptData`  
- Imports techno-economic parameters
- Processes unit definitions
- Handles currency conversions

#### `ProfilesOptData`
- Reads renewable energy time series
- Processes electricity price data
- Validates profile completeness (8760 hours)

#### `LciaOptData`
- Life cycle impact assessment data
- Emission factors by technology
- Environmental impact calculations

### SolveModel Module

Optimization engine components:

#### `Solve_LP`
- Single-objective linear programming
- Cost minimization optimization
- Capacity and operational constraints

#### `Solve_LP_2obj`
- Multi-objective optimization
- Pareto frontier generation
- Trade-off analysis (cost vs. emissions)

**Decision Variables:**
```julia
@variable(Model_LP, Capacity[1:U] >= 0)          # Installed capacity
@variable(Model_LP, X[1:U, t in Time] >= 0)     # Hourly production
@variable(Model_LP, Sold[1:U, t in Time] >= 0)  # Sales
@variable(Model_LP, Bought[1:U, t in Time] >= 0) # Purchases
```

**Key Constraints:**
- Energy balance: Production = Consumption
- Capacity limits: Production ≤ Installed capacity
- Ramping constraints (optional)
- Minimum load factors
- Mass balance for conversion processes

### WriteResults Module

#### `Results_LP`
- Formats optimization results
- Calculates derived metrics
- Exports to CSV format
- Generates summary statistics

**Key Metrics Calculated:**
- Levelized cost of fuel (LCOF)
- Capacity factors and full load hours
- Annual production and consumption
- Economic breakdown by cost category

## Plotting and Visualization

### PlotGraphs Module

Streamlit-based interactive dashboards:

#### `Dashboard_CO2.py`
- Carbon intensity analysis
- Emission factor comparisons
- Life cycle assessment visualization

#### `Dashboard_Daily.py`  
- Hourly operational profiles
- Renewable energy utilization
- System load patterns

#### `Dashboard_Scenarios.py`
- Multi-scenario comparisons
- Sensitivity analysis plots
- Economic trade-offs

#### `CAP.py`, `INV.py`
- Capacity and investment analysis
- Technology comparisons
- Cost breakdown charts

## Utility Functions

### File Handling
```julia
read_xlsx(filename, sheetname)    # Excel file reader with missing value handling
```

### Path Management
```julia
joinpath(Main_folder, Project, "Data", "Inputs")  # Cross-platform path construction
mkpath(result_folder)                             # Directory creation
```

### Data Processing
```julia
coalesce.(data, 0)               # Replace missing values with zeros
findfirst(x -> x == "Parameter", array)  # Find parameter locations in Excel
```

## Error Handling

### Common Error Types

**InfeasibleError**: Optimization problem has no solution
- Check renewable resource adequacy
- Verify unit compatibility in `Selected_units`
- Ensure profile data completeness

**BoundsError**: Array index out of bounds  
- Verify Excel sheet structure matches expected format
- Check for missing columns in input data
- Confirm scenario numbers exist

**FileNotFoundError**: Missing input files
- Verify file paths and names
- Check folder structure integrity
- Ensure Excel files are not corrupted

### Debugging Tips

1. **Enable detailed logging:**
   ```julia
   ENV["JULIA_DEBUG"] = "OptiPlantPtX"
   ```

2. **Test with simple cases:**
   - Single scenario, short time period
   - Verify with example data first

3. **Check solver status:**
   ```julia
   termination_status(Model_LP)  # Should return MOI.OPTIMAL
   ```

## Performance Considerations

### Solver Selection
- **HiGHS**: Fast for most problems, open source
- **Gurobi**: Better for large problems, requires license

### Problem Size Scaling
- **Small problems** (<100 MW, <1000 hours): Either solver
- **Large problems** (>1 GW, full year): Gurobi recommended
- **Memory usage**: ~1-2 GB per large scenario

### Parallel Processing Guidelines
- **Sequential**: Up to 10 scenarios
- **Parallel**: 10+ scenarios with 4+ CPU cores
- **Memory**: 2-4 GB per parallel worker

## See Also

- [Installation Guide](installation.md) for setup instructions
- [Usage Guide](usage.md) for configuration details  
- [Examples](Examples.md) for practical applications
- [GitHub Repository](https://github.com/njbca/OptiPlant) for source code