# Technical Specifications and API Reference

This section provides detailed technical specifications for OptiPlant's file formats, solver integration, and performance requirements.

## Model Specifications

### Mathematical Framework

**OptiPlant** implements a linear programming (LP) optimization model with the following characteristics:

- **Objective**: Minimize annualized system cost
- **Constraint**: Meet specified yearly fuel demand  
- **Approach**: Dynamic power supply and system optimization (DPS-Syst-Opt)
- **Foresight**: Perfect foresight with hourly resolution
- **Time horizon**: Annual optimization (8760 hours)

### Optimization Problem Structure

```
minimize: Investment_costs + Operational_costs

subject to:
- Annual fuel demand satisfaction
- Unit operational constraints  
- Mass and energy balance equations
- Storage capacity limitations
- Renewable resource availability
- Grid electricity purchase limits
```

## File Format Specifications

### Excel Input File Structure

#### Data_base_case Sheet Format

| Column | Parameter | Type | Units | Description |
|--------|-----------|------|-------|-------------|
| A | Unit_name | String | - | Technology identifier |
| B | Unit_type | String | - | "electrical" or "non-electrical" |
| C | Production_rate | Float | t/h or MW | Nominal output capacity |
| D | Heat_flow | Float | MW | Heat integration requirements |
| E | Electrical_flow | Float | MW | Electricity consumption/generation |
| F | Load_min | Float | % | Minimum operational load |
| G | Load_max | Float | % | Maximum operational load |
| H | Ramp_up | Float | %/h | Maximum ramp-up rate |
| I | Ramp_down | Float | %/h | Maximum ramp-down rate |
| J | CapEx | Float | €/unit | Capital expenditure |
| K | OpEx_fixed | Float | €/unit/year | Fixed operational costs |
| L | OpEx_variable | Float | €/t or €/MWh | Variable operational costs |
| M | Lifetime | Integer | years | Technology lifetime |
| N | Yearly_demand | Float | t/year | Default fuel demand (if applicable) |

#### Selected_units Sheet Format

```
       NH3  H2  MeOH  [Additional_Fuels...]
Unit1   1   0    1    
Unit2   1   1    0    
Unit3   0   1    1    
[...]
```

- **Rows**: Available technologies/units
- **Columns**: Fuel production pathways  
- **Values**: 1 = included, 0 = excluded

#### Scenarios_definition Sheet Format

| Column | Parameter | Type | Description |
|--------|-----------|------|-------------|
| A | Scenario_name | String | Unique scenario identifier |
| B | Parameter_1 | Float | First sensitivity parameter |
| C | Parameter_2 | Float | Second sensitivity parameter |
| ... | ... | ... | Additional parameters as needed |

#### ScenariosToRun Sheet Format

| Column | Parameter | Type | Example | Description |
|--------|-----------|------|---------|-------------|
| A | Scenario | String | "base_case" | Scenario identifier |
| B | Location | String | "Denmark" | Geographic location |
| C | Year | Integer | 2019 | Profile data year |
| D | Fuel | String | "NH3" | Target fuel type |
| E | Electrolyzer | String | "PEM" | Technology selection |
| F | Results_folder | String | "Results_base" | Output directory name |

### Profile Data Format

#### Flux Sheet (Renewable Profiles)

```
Hour | Wind_Tech1_Loc1 | Wind_Tech2_Loc1 | Solar_Tech1_Loc1 | ...
1    | 0.45           | 0.52           | 0.0              |
2    | 0.48           | 0.55           | 0.0              |
...  | ...            | ...            | ...              |
8760 | 0.42           | 0.49           | 0.0              |
```

- **Units**: Normalized capacity factors (0-1)
- **Resolution**: Hourly (8760 rows per year)
- **Sources**: Wind (CorRES), Solar (renewable.ninja)

#### Price Sheet (Electricity Prices)

```
Hour | Location1_Price | Location2_Price | ...
1    | 45.2           | 48.7           |
2    | 43.8           | 46.3           |
...  | ...            | ...            |
8760 | 47.1           | 50.2           |
```

- **Units**: €/MWh (or local currency per MWh)
- **Resolution**: Hourly (8760 rows per year)

## Julia Code Structure

### Main.jl Configuration Parameters

#### Required Solver Setting
```julia
solver = "HiGHS"  # or "Gurobi"
```

#### Directory Configuration
```julia
OptiPlant_directory = "/path/to/OptiPlant-master"
input_data_excel_file_name = "Input_data_example"  # without .xlsx
input_data_excel_sheet_name = "ScenariosToRun"
results_folder_name = "Results_base_case"
```

#### Optional Advanced Settings
```julia
# Solver-specific options
solver_time_limit = 3600  # seconds
solver_gap_tolerance = 0.01  # 1% optimality gap
```

### Package Dependencies

#### Required Packages
```julia
using JuMP          # Optimization modeling framework
using HiGHS         # Open-source LP solver (recommended)
using DataFrames    # Structured data manipulation  
using CSV           # CSV file I/O operations
using XLSX          # Excel file reading
```

#### Optional Packages
```julia
using Gurobi        # Commercial LP solver (alternative)
using Plots         # Results visualization
using StatsPlots    # Statistical plotting
using PrettyTables  # Formatted output display
```

## Solver Integration

### HiGHS Solver (Recommended)

**Installation:**
```julia
] add HiGHS
```

**Advantages:**
- Open-source and free
- Fast performance for LP problems
- Active development and support
- No licensing requirements

**Typical Performance:**
- Solve time: <5 minutes for standard problems
- Memory usage: <2GB RAM
- Scalability: Handles large-scale problems efficiently

### Gurobi Solver (Commercial Alternative)

**Installation:**
```julia
] add Gurobi
```

**Prerequisites:**
- Valid Gurobi license (academic/commercial)
- Gurobi Optimizer software installation
- License activation via `grbgetkey`

**Advantages:**
- Potentially faster for very large problems
- Advanced optimization features
- Commercial support available

**Performance Notes:**
- Identical results to HiGHS for OptiPlant problems
- May offer speed advantages for complex constraint sets

## Output File Specifications

### CSV Output Structure

#### Main Results Files

**Installed_capacities.csv:**
```
Unit_name,Capacity_MW,Capacity_t_h,Investment_cost_EUR
Electrolyzer_PEM,150.5,0.0,45150000
H2_storage,0.0,2500.8,12504000
Wind_turbine,500.2,0.0,75030000
```

**Operation_results.csv:**
```
Hour,Unit_name,Power_MW,Mass_flow_t_h,Operational_cost_EUR
1,Electrolyzer_PEM,125.4,0.0,2508
1,H2_storage,0.0,15.2,0
2,Electrolyzer_PEM,98.7,0.0,1974
```

#### Hourly Results Files

**Hourly_flows.csv:**
- **Columns**: Time, Unit flows, Storage levels, Grid interactions
- **Resolution**: 8760 hourly time steps
- **Units**: MW for electrical, t/h for mass flows

### Results Analysis Integration

#### Excel Macro Requirements

The Results.xlsx file uses VBA macros for CSV import:

```vba
' Import macro expects:
' - Main results folder path (ending with "\")
' - Hourly results folder path (ending with "\")  
' - CSV files with standard OptiPlant naming convention
```

#### Pivot Table Configuration

Automated Pivot Tables require:
- **Data source**: Imported CSV data ranges
- **Field mappings**: Predefined for OptiPlant output structure  
- **Chart templates**: Configured for standard analysis types

## Performance Requirements

### System Specifications

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **RAM** | 4 GB | 8 GB+ | Large models may require more |
| **CPU** | Dual-core | Quad-core+ | Multi-threading improves solve time |
| **Storage** | 2 GB free | 5 GB+ free | For results and temporary files |
| **OS** | Windows 10, macOS 10.14, Ubuntu 18.04+ | Latest versions | Julia compatibility |

### Computational Complexity

**Model Size Scaling:**
- **Variables**: O(N_units × N_hours) ≈ 50-200 units × 8760 hours
- **Constraints**: O(N_scenarios × N_hours) ≈ 1-10 scenarios × 8760 hours  
- **Solve time**: Generally linear with problem size for LP problems

**Memory Usage Patterns:**
- **Data loading**: 100-500 MB for input processing
- **Model building**: 200MB-2GB depending on complexity
- **Solver execution**: 500MB-4GB peak memory usage

## Error Handling and Validation

### Input Data Validation

OptiPlant performs automatic validation of:

1. **Excel file structure**: Required sheets and columns
2. **Parameter ranges**: Physical constraints and realistic values  
3. **Data consistency**: Unit matching across sheets
4. **Profile completeness**: Full 8760-hour datasets

### Common Error Types

#### Model Infeasibility
```
ERROR: Model infeasible
Cause: Contradictory constraints or impossible demand targets
Solution: Review unit capacities and demand requirements
```

#### Data Format Errors  
```
ERROR: Expected Float64, got String
Cause: Non-numeric data in parameter fields
Solution: Check Excel cells for text in numeric columns
```

#### File Access Errors
```
ERROR: File not found
Cause: Incorrect paths or missing files
Solution: Verify all path specifications in Main.jl
```

## Advanced Configuration

### Custom Unit Integration

To add new technologies:

1. **Define parameters** in Data_base_case sheet
2. **Set selection logic** in Selected_units sheet  
3. **Update constraints** in Julia code if needed
4. **Validate performance** with test scenarios

### Multi-objective Optimization

OptiPlant can be extended for multi-objective problems:

```julia
# Example: Cost + emissions minimization
@objective(model, Min, 
    investment_costs + operational_costs + 
    emission_penalty * total_emissions
)
```

### Custom Solver Options

Advanced solver configuration:

```julia
# HiGHS options
set_optimizer_attribute(model, "time_limit", 3600.0)
set_optimizer_attribute(model, "mip_rel_gap", 0.01)

# Gurobi options (if available)
set_optimizer_attribute(model, "TimeLimit", 3600)
set_optimizer_attribute(model, "MIPGap", 0.01)
```

## Integration Guidelines

### External Tool Integration

OptiPlant can interface with:

- **GIS tools**: For location-specific resource assessment
- **Database systems**: For large-scale parameter management
- **Visualization software**: For advanced results processing
- **Economic models**: For market price integration

### Workflow Automation

Batch processing capabilities:

```julia
# Example: Automated scenario execution
for scenario in scenario_list
    update_parameters(scenario)
    solve_model()
    export_results(scenario.name)
end
```

## Version Compatibility

### Julia Version Requirements
- **Minimum**: Julia 1.6+
- **Recommended**: Julia 1.8+
- **Package compatibility**: Verified with latest LTS releases

### Excel Version Support
- **Windows**: Excel 2016+ recommended
- **macOS**: Excel 2016+ or Numbers with CSV import
- **LibreOffice**: Calc 6.0+ with macro support

---

**Technical Reference Complete!** This specification covers all technical aspects of OptiPlant implementation and usage.