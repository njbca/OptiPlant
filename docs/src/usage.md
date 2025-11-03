# Usage

This guide covers how to use OptiPlant.jl for Power-to-X system modeling and optimization, from basic single-scenario runs to advanced multi-scenario analyses.

## Basic Concepts

### System Architecture

OptiPlant.jl models Power-to-X fuel production systems using:
- **Units**: Individual components (electrolyzers, storage, conversion units, etc.)  
- **Time series**: Hourly profiles for renewable energy and electricity prices
- **Scenarios**: Different system configurations and operational parameters
- **Optimization**: Linear programming to minimize total system costs

### Folder Structure

OptiPlant follows a specific project structure:

```
Project_Name/
├── Data/
│   ├── Inputs/           # Configuration and techno-economic data
│   └── Profiles/         # Renewable energy and price time series
├── Results/              # Optimization results and outputs
└── Code/                 # Julia optimization scripts
```

## Quick Start

### Running Your First Optimization

1. **Select your input data file** in the main run script:
   ```julia
   # In Run.jl or your main script
   Inputs_file = "Input_data_example"  # Start with the example
   ```

2. **Configure basic settings:**
   ```julia
   Solver = "HiGHS"          # Use open-source solver
   Project = "Base"          # Project folder name
   N_scen_0 = 1             # First scenario to run
   N_scen_end = 1           # Last scenario to run
   ```

3. **Run the optimization:**
   ```julia
   using OptiPlantPtX
   include("Run.jl")  # Or execute in VS Code
   ```

### Understanding Results

Results are automatically saved in `Project/Results/` with:
- **Main results**: Overall system economics and capacity
- **Hourly results**: Time series of operation and flows  
- **Data used**: Input parameters for reproducibility

## Configuration

### Input Data Files

OptiPlant uses Excel files in `Data/Inputs/` with structured sheets:

#### Core Sheets:

**Data_base_case**: Techno-economic parameters
```
Type of units | Investment (EUR/Capacity) | Fixed O&M | Variable O&M | ...
Electrolyzer  | 1000000                  | 25000     | 0.01         | ...
H2_storage    | 500000                   | 10000     | 0.005        | ...
```

**Selected_units**: Enable/disable units for scenarios
```
Unit Type     | Scenario_1 | Scenario_2 | ...
Electrolyzer  | 1          | 1          | ...
Ammonia_plant | 1          | 0          | ...
```

**ScenariosToRun**: Define scenarios to execute
```
Scenario | Location    | Fuel     | Year | Profile  | Electrolyser | ...
1        | Denmark     | Hydrogen | 2019 | DK1_2019 | AEL          | ...
2        | Antofagasta | Ammonia  | 2019 | ANF_2019 | PEM          | ...
```

### Profile Data

Time series data in `Data/Profiles/Location/`:
- **Renewable energy**: Wind and solar capacity factors (0-1)
- **Electricity prices**: EUR/MWh for each hour
- **Format**: CSV with hourly data (8760 hours for full year)

Example profile structure:
```csv
Hour,Wind_offshore,Solar_PV,Electricity_price
1,0.45,0.0,45.2
2,0.52,0.0,43.8
...
```

## Advanced Usage

### Multi-Scenario Analysis

Run multiple scenarios in sequence:

```julia
N_scen_0 = 1      # Start scenario
N_scen_end = 10   # End scenario (runs scenarios 1-10)
```

Or use parallel processing:
```julia
include("Run_multi_scenarios_para.jl")  # Parallel execution
```

### Scenario Definitions

Create advanced scenarios using the `Scenarios_definition` sheet:

```excel
Reference scenario | Scenario name | Parameter changed | New value
Base_case         | High_CAPEX    | Investment        | 1200000
Base_case         | Low_efficiency | Electrical cons.  | 55
```

This allows systematic sensitivity analysis by modifying specific parameters.

### Time Period Configuration

Control simulation time periods:

```julia
# Full year simulation
TMstart = 1; TMend = 8760; Tbegin = 1; Tfinish = 8760

# Maintenance periods (exclude summer maintenance)
TMstart = 4000; TMend = 4876; Tbegin = 72; Tfinish = 8760

# Short test run (first week)
TMstart = 1; TMend = 168; Tbegin = 1; Tfinish = 168
```

### Solver Configuration

#### HiGHS (Open Source)
```julia
Solver = "HiGHS"
# No additional configuration needed
```

#### Gurobi (Commercial)
```julia
Solver = "Gurobi"
# Requires license activation: grbgetkey YOUR_LICENSE_KEY
```

### Output Options

Control result granularity:

```julia
# In scenario configuration
Write_flows = true   # Save detailed hourly flows
Option_ramping = true # Include ramping constraints
```

## System Configuration Options

### Available Technologies

OptiPlant includes models for:
- **Electrolyzers**: AEL (Alkaline), PEM (Proton Exchange Membrane)
- **Storage**: Hydrogen tanks, batteries
- **Conversion**: Ammonia synthesis, methanol production  
- **Renewable**: Wind (onshore/offshore), Solar PV, CSP
- **Grid**: Electricity import/export

### Operational Constraints

Configure realistic operational limits:

```julia
# In techno-economic data
Max_Capacity = 100      # MW maximum size
Load_min = 0.1          # 10% minimum load
Ramp_up = 0.5          # 50% capacity/hour ramp rate  
Ramp_down = 0.7        # 70% capacity/hour ramp down
```

### Economic Parameters

All economic data in EUR 2019:
- **Investment costs**: EUR/capacity installed
- **Fixed O&M**: EUR/capacity/year  
- **Variable O&M**: EUR/output
- **Fuel prices**: EUR/output
- **Discount rate**: Built into annuity factors

## Results Analysis

### Main Results Structure

Key output metrics for each unit:
- `Installed_capacity`: Optimal capacity (MW or t/h)
- `Investment`: Total and annualized investment (M€)
- `Production`: Annual output (kton or GWh)  
- `Full_load_hours`: Capacity utilization
- `Production_cost`: EUR/kg fuel or EUR/MWh

### Interpreting Results

**System Levelized Cost**:
```
LCOF = (Annualized Investment + O&M + Fuel Costs) / Annual Production
```

**Capacity Factor**:
```  
CF = Full Load Hours / 8760 hours
```

**Economics**:
- Compare production costs across scenarios
- Identify cost drivers (investment vs. operational)
- Analyze sensitivity to key parameters

## Common Use Cases

### 1. Technology Comparison
Compare different electrolyzer technologies:
```julia
# Scenario 1: AEL electrolyzer
# Scenario 2: PEM electrolyzer  
# Compare: investment costs, efficiency, flexibility
```

### 2. Location Assessment  
Evaluate different sites:
```julia
# Multiple scenarios with different locations
# Compare: resource quality, electricity prices, LCOF
```

### 3. Sensitivity Analysis
Test parameter impacts:
```julia
# Vary: CAPEX (-20%, +20%), efficiency (±5%), fuel prices  
# Analyze: cost sensitivity, optimal design changes
```

### 4. Optimal Sizing
Find cost-optimal capacity:
```julia
# Enable: Option_max_capacity = true
# Result: Economically optimal plant size
```

## Troubleshooting

### Common Issues

**Infeasible Solutions**:
- Check unit compatibility in `Selected_units`
- Verify profile data completeness (8760 hours)
- Ensure renewable resource adequacy

**Slow Performance**:
- Reduce time resolution for initial studies  
- Disable ramping constraints for faster solving
- Use Gurobi for large problems

**File Path Errors**:
- Use absolute paths in configuration
- Verify folder structure matches expected layout
- Check Excel file names and sheet names

### Performance Tips

1. **Start simple**: Use example data, single scenario, HiGHS solver
2. **Scale up gradually**: Add complexity after verifying basic functionality  
3. **Profile first**: Test with short time periods before full year
4. **Parallel processing**: Use for multiple scenarios with sufficient CPU cores

## Next Steps

- Explore [Examples](Examples.md) for detailed use cases
- Check [API Reference](api.md) for function documentation  
- Set up [Streamlit dashboards] for interactive visualization
- Review the User Guide for additional configuration details