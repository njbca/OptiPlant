# Examples

This page provides practical examples for common OptiPlant.jl use cases, from basic single-scenario runs to advanced multi-scenario analyses and dashboard visualization.

## Basic Examples

### Single Scenario Optimization

The simplest way to run OptiPlant is with a single scenario using the example data:

```julia
# Basic setup
using OptiPlantPtX

# Configure paths (adjust to your installation)
Main_folder = "C:/path/to/OptiPlant"
Project = "Base" 
Inputs_file = "Input_data_example"
Solver = "HiGHS"  # or "Gurobi" if available

# Run single scenario
N_scen_0 = 1; N_scen_end = 1
include("examples/Run.jl")
```

This will:
- Load the example techno-economic data
- Run optimization for scenario 1  
- Save results in `Base/Results/`

### Quick Test Run

For faster testing, limit the simulation to one week:

```julia
# In your main run script
TMstart = 1; TMend = 168  # First week (168 hours)
Tbegin = 1; Tfinish = 168

# Keep other settings the same
include("Run.jl")
```

## Technology Comparison Examples

### Electrolyzer Technology Assessment

Compare Alkaline (AEL) vs. PEM electrolyzers for hydrogen production:

**Setup scenarios in Excel (`ScenariosToRun` sheet):**
```
Scenario | Location | Fuel     | Electrolyser | Profile  | Year
1        | Denmark  | Hydrogen | AEL         | DK1_2019 | 2019
2        | Denmark  | Hydrogen | PEM         | DK1_2019 | 2019  
```

**Run comparison:**
```julia
N_scen_0 = 1; N_scen_end = 2  # Run both scenarios
include("Run.jl")

# Results will be in separate CSV files:
# - Scenario_1.csv (AEL results)  
# - Scenario_2.csv (PEM results)
```

**Key metrics to compare:**
- Production cost (EUR/kg H₂)
- Investment requirements (M€)
- Full load hours
- Electrical consumption (kWh/kg)

### Fuel Production Comparison  

Compare hydrogen vs. ammonia production at the same location:

```
Scenario | Location    | Fuel    | Electrolyser | Profile   
1        | Antofagasta | Hydrogen| PEM         | ANF_2019  
2        | Antofagasta | Ammonia | PEM         | ANF_2019   
```

This compares:
- System complexity (H₂ only vs. H₂ + NH₃ synthesis)
- Investment costs
- Production costs
- Resource utilization

## Location Assessment Examples

### Multi-Location Analysis

Evaluate the same system across different renewable resource locations:

```julia
# Define locations in scenarios
locations = ["Denmark", "Antofagasta", "Bornholm", "Faroes"]
scenarios = 1:length(locations)

N_scen_0 = 1; N_scen_end = 4
include("Run.jl")
```

**Excel setup:**
```
Scenario | Location    | Fuel     | Profile   | Year
1        | Denmark     | Hydrogen | DK1_2019  | 2019
2        | Antofagasta | Hydrogen | ANF_2019  | 2019  
3        | Bornholm    | Hydrogen | BOR_2019  | 2019
4        | Faroes      | Hydrogen | FAR_2019  | 2019
```

Compare:
- Renewable resource quality (capacity factors)
- Electricity prices  
- Resulting production costs
- Optimal system sizing

### Resource Quality Impact

Analyze how renewable resource profiles affect system design:

```julia
# Use profiles from different years for the same location
profiles = ["DK1_2018", "DK1_2019", "DK1_2020"]

# Or compare onshore vs offshore wind profiles
profiles = ["DK1_onshore_2019", "DK1_offshore_2019"]
```

## Advanced Examples

### Sensitivity Analysis

Test system response to parameter variations using scenario definitions:

**In Excel `Scenarios_definition` sheet:**
```
Reference | Scenario_name    | Parameter_changed | New_value
Base_case | High_CAPEX      | Investment        | 1200000
Base_case | Low_CAPEX       | Investment        | 800000  
Base_case | High_efficiency | Electrical cons.  | 45
Base_case | Low_efficiency  | Electrical cons.  | 60
```

**Run sensitivity study:**
```julia
Scenarios_set = "Scenarios_sensitivities"  # Different scenario sheet
N_scen_0 = 1; N_scen_end = 4
include("Run.jl")
```

### Multi-Year Analysis

Analyze system performance across multiple years:

```julia
# Setup scenarios for different years
years = [2018, 2019, 2020]
profiles = ["DK1_2018", "DK1_2019", "DK1_2020"]

# Configure in Excel and run
N_scen_0 = 1; N_scen_end = 3
include("Run.jl")
```

This helps understand:
- Inter-annual variability impact
- System robustness to weather variations
- Long-term performance expectations

### Parallel Processing

For large scenario sets, use parallel processing:

```julia
# Use parallel version for multiple scenarios
include("Run_multi_scenarios_para.jl")

# Or manually configure parallel workers
using Distributed
addprocs(4)  # Use 4 CPU cores

@everywhere using OptiPlantPtX
# Run scenarios in parallel
```

## Dashboard Examples

### Interactive Analysis with Streamlit

Set up Python environment and run dashboards:

```powershell
# Create Python environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install requirements  
pip install -r requirements.txt

# Run dashboards
streamlit run src/PlotGraphs/Dashboard_CO2.py      # CO₂ analysis
streamlit run src/PlotGraphs/Dashboard_Daily.py    # Daily operation  
streamlit run src/PlotGraphs/Dashboard_Scenarios.py # Scenario comparison
```

### Dashboard Configuration

**Data Loading:**
- Dashboards read from `Base/Results/` folder
- Select scenario CSV files interactively
- Debug panel shows data parsing issues

**Visualization Options:**
- **Capacity plots**: Investment and installed capacity by unit
- **Daily profiles**: Hourly operation patterns
- **Economic analysis**: Cost breakdown and sensitivity
- **CO₂ analysis**: Emission factors and carbon intensity

### Custom Dashboard Setup

Create custom visualizations:

```python
import streamlit as st
import pandas as pd
import plotly.express as px

# Load OptiPlant results
df = pd.read_csv("Base/Results/YourScenario/Scenario_1.csv")

# Create custom plots
fig = px.bar(df, x='Type of unit', y='Installed capacity', 
             title='System Configuration')
st.plotly_chart(fig)
```

## Configuration Examples

### Custom Input Data

Create new input file based on existing template:

1. **Copy template:**
   ```julia
   # Copy existing input file
   cp("Base/Data/Inputs/Input_data_example.xlsx", 
      "Base/Data/Inputs/My_custom_input.xlsx")
   ```

2. **Modify parameters** in Excel sheets:
   - `Data_base_case`: Update techno-economic parameters
   - `Selected_units`: Choose active units  
   - `ScenariosToRun`: Define your scenarios

3. **Update run script:**
   ```julia
   Inputs_file = "My_custom_input"
   ```

### New Location Setup

Add custom location with renewable profiles:

1. **Create profile folder:**
   ```
   Base/Data/Profiles/My_Location/
   ```

2. **Add profile CSV** with columns:
   ```csv
   Hour,Wind_offshore,Wind_onshore,Solar_PV,Electricity_price
   1,0.42,0.38,0.0,45.2
   2,0.48,0.41,0.0,43.8
   ...
   ```

3. **Configure in scenarios:**
   ```
   Location | Profile_name     | Profile_folder_name
   My_Location | Custom_2019   | My_Location
   ```

### Technology Addition

Add new unit type to the system:

1. **Define in techno-economics sheet:**
   - Add row with unit parameters
   - Set investment costs, efficiency, etc.

2. **Update unit selection:**
   - Include in `Selected_units` sheet
   - Set to 1 for active scenarios

3. **Configure connectivity:**
   - Define input/output flows
   - Set mass/energy balances

## Troubleshooting Examples

### Common Issues and Solutions

**Infeasible Solution:**
```julia
# Check if renewable resources are sufficient
# Reduce load or increase renewable capacity

# Verify unit compatibility  
# Check Selected_units sheet for required units
```

**File Path Errors:**
```julia  
# Use absolute paths
Main_folder = "C:/Users/YourName/Documents/OptiPlant"

# Verify folder structure exists
if !isdir(joinpath(Main_folder, Project, "Data"))
    error("Project folder not found")
end
```

**Performance Issues:**
```julia
# Start with shorter time periods
TMstart = 1; TMend = 24  # One day only

# Use HiGHS for initial testing  
Solver = "HiGHS"

# Disable complex constraints initially
Option_ramping = false
Write_flows = false
```

### Debugging Workflow

1. **Start simple**: Single scenario, short time period
2. **Verify data**: Check input file formatting and completeness
3. **Test solver**: Ensure HiGHS/Gurobi installation works
4. **Scale gradually**: Add complexity incrementally
5. **Check results**: Verify outputs are reasonable

## Next Steps

- Review [Installation](installation.md) for setup details
- Check [Usage](usage.md) for configuration options  
- Explore [API Reference](api.md) for detailed function documentation
- Join GitHub discussions for community support
