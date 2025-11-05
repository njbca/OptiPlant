# File Structure and Usage

This guide explains the OptiPlant file organization and how to use the tool effectively.

## OptiPlant File Structure Overview

After downloading and extracting OptiPlant, you will see the following structure:

![OptiPlant File Structure](images/Fig.15.png)

```
OptiPlant-master/
├── BASE/
│   ├── Data/
│   │   ├── Inputs/           # Excel files with plant units and scenarios
│   │   └── Profiles/         # Wind/solar profiles and electricity prices
│   └── Results/              # Output folders (created automatically per run)
└── RUN CODE/
    ├── ImportData.jl         # Data import functions
    ├── ImportScenarios.jl    # Scenario configuration
    └── Main.jl               # Main optimization model
```

### Main Directories Explained

- **BASE**: Contains all data and results (not code-related)
- **RUN CODE**: Contains the Julia scripts to import data, define scenarios, and run the optimization model

## RUN CODE Folder

### Contents and Purpose

The RUN CODE folder contains three main Julia files:

![RUN CODE Contents](images/Fig.35.png)

1. **ImportData.jl**: Imports into Julia the necessary input data (units, techno-economics, power profiles)
2. **ImportScenarios.jl**: Imports information regarding the scenario conditions of the study
3. **Main.jl**: The optimization model that uses imported data and extracts outputs

### Running OptiPlant

#### Main.jl Configuration

Open `Main.jl` in VS Code and configure the following settings:

![Main.jl Solver Configuration](images/Fig.36.png)

**Line 4 - Solver Selection:**
```julia
solver = "HiGHS"    # or "Gurobi"
```

![Main.jl Directory Configuration](images/Fig.37.png)

**Lines 22-25 - Directory Configuration:**
```julia
# Set these paths according to your setup:
OptiPlant_directory = "C:/path/to/your/OptiPlant-master"
input_data_excel_file_name = "Input_data_example"
input_data_excel_sheet_name = "ScenariosToRun"  
results_folder_name = "Results_base_case"
```

#### Execution Steps

1. Open `RUN CODE/Main.jl` in VS Code
2. Set solver preference (line 4)
3. Configure directory paths (lines 22-25)
4. If you create a new scenarios sheet, update the reference in Main.jl (e.g., line 28)
5. Run the file (`Ctrl+Enter` or click Run)

**Typical execution time**: Less than 5 minutes

## BASE Folder Structure

### Data Subfolder

The Data folder contains two main subfolders:

#### Inputs Subfolder

Contains Excel workbooks with all model parameters and scenarios.

![Inputs Folder](images/Fig.16.png)

**Standard Excel File Structure** (e.g., "Input_data_example.xlsx"):

##### 1. Data_base_case Sheet
Contains the list of possible units and their characteristics:

![Data_base_case Sheet](images/Fig.17.png)

- **Non-electrical and electrical units** with production rates
- **Heat/electrical flows** and load ranges  
- **Ramp constraints** and operational limits
- **CapEx and OpEx** economic parameters
- **Default yearly demands** (red box - main model drivers)

![Unit Characteristics Detail](images/Fig.18.png)

##### 2. Selected_units Sheet
1/0 matrix indicating which units/technologies are included per fuel production process:

![Selected_units Sheet](images/Fig.19.png)

- **Columns**: Different fuel types (NH₃, H₂, MeOH, etc.)
- **Rows**: Available technologies/units
- **Values**: 1 = included, 0 = excluded
- **Use**: Define technology combinations for each fuel type

##### 3. Scenarios_definition Sheet
Defines operating strategy and conditions:

![Scenarios_definition Sheet](images/Fig.20.png)

- **Intermediate logic** between base case data and outputs
- **Sensitivity analysis** parameter variations
- **Operating strategies** for different conditions

##### 4. ScenariosToRun Sheet
Lists the scenarios to execute:

![ScenariosToRun Sheet](images/Fig.21.png)

Key parameters per scenario:
- **Operating strategy**
- **Location** (wind/solar data)
- **Year** (for profiles)
- **Produced fuel** type
- **Electrolyzer technology**
- **Results folder naming**

##### 5. Sources Sheet
References and sources for all data entries:

![Sources Sheet](images/Fig.22.png)

- **Parameter sources** and references
- **Data validation** information  
- **Update guidance** for parameter modifications

#### Profiles Subfolder

Contains renewable energy and electricity price data organized by year:

![Profiles Folder](images/Fig.23.png)

**Example: 2019.xlsx workbook structure:**

![Profiles Workbook](images/Fig.24.png)

##### Flux Sheet
Hourly normalized generator output profiles:

![Flux Sheet](images/Fig.25.png)

- **Solar profiles** for various technologies and locations
- **Wind profiles** for different turbine types and locations  
- **Normalized values** (0-1 range representing capacity factor)
- **8760 hours** per year
- **Data sources**: 
  - Wind: CorRES tool
  - Solar: renewable.ninja website

##### Price Sheet
Hourly electricity grid prices:

![Price Sheet](images/Fig.26.png)

- **Hourly electricity buy prices** 
- **Different locations** and price zones
- **Currency units** as specified
- **8760 hours** per year of price data

### Results Subfolder

Generated automatically when running OptiPlant simulations.

![Results Folder Structure](images/Fig.27.png)

#### Results Organization

Each simulation creates a separate folder (named per ScenariosToRun sheet):

![Individual Results Folder](images/Fig.28.png)

**Each results folder contains:**
- **Data used** (CSV files with input data actually used)
- **Hourly results** (CSV files with time-series outputs)  
- **Main results** (CSV files with summary outputs)

#### Results Excel File

Use the provided "Results.xlsx" file for visualization:

![Results Excel File](images/Fig.29.png)

**Placement**: Copy Results.xlsx into your specific results folder

![Results File Placement](images/Fig.30.png)

#### Import and Analysis Process

##### Import Sheet Configuration

![Import Sheet](images/Fig.31.png)

1. Set **"Main results folder"** path (must end with "\")
2. Set **"Hourly results folder"** path (must end with "\")  
3. Click **macro buttons** to import CSV data

##### Results Analysis Sheets

**All_scenarios Sheet:**

![All_scenarios Sheet](images/Fig.32.png)

- **Output values** for each unit and scenario
- **Comparative analysis** across scenarios
- **Unit performance** summaries

**Specialized Analysis Sheets:**

![Analysis Charts Example](images/Fig.33.png)

Available analysis sheets:
- **"Elec production"** - Electricity generation breakdown
- **"Electricity consumption"** - Power usage analysis  
- **"Production cost"** - Cost analysis and breakdown
- **"Cost breakdown"** - Detailed cost components
- **"Installed capacities"** - System sizing results

**Pivot Table Integration:**
- Automatic chart generation via Pivot Tables
- **Refresh pivots** after importing new results
- Customizable visualizations

##### Hourly Results Analysis

![Hourly Results Example](images/Fig.34.png)

When hourly results are imported:
- **Additional sheets** created per scenario
- **Time-series data** for all system flows
- **Hourly resolution** for detailed analysis

#### Output Units

| Component Type | Units |
|----------------|-------|
| **Non-electrical units** | t/h (tonnes per hour) |
| **Electrical units** | MW (megawatts) |
| **Hourly flows** | kg/h and kW (values ÷ 1000) |  
| **Mass storage** | t (tonnes) |
| **Electricity storage** | MWh (megawatt-hours) |

## Data Requirements and Preparation

### Input Data Guidelines

1. **Data_base_case**: Update only if necessary - units and sources are provided
2. **Selected_units**: Set 1/0 according to preference (work on copies to track changes)
3. **Scenarios_definition**: Adjust scenario logic for sensitivity analysis  
4. **ScenariosToRun**: Carefully type names that must match other sheets
5. **Sources**: Maintain if inputs are changed

### Profile Data Sources

- **Wind profiles**: Generated using CorRES tool
- **Solar profiles**: Downloaded from renewable.ninja website  
- **Electricity prices**: Historical or projected hourly prices by location

### Best Practices

1. **Keep backups** of standard input files to revert changes
2. **Maintain consistent naming** across Excel sheets and Main.jl references
3. **Verify file paths** in Main.jl configuration
4. **Check scenario names** match between sheets
5. **Update Sources sheet** when modifying input parameters

## Troubleshooting File Operations

### Path Configuration Issues

![Path Configuration Example](images/Fig.40.png)

**Common Problems:**
- Incorrect directory separators (use `/` or `\\`)
- Missing trailing slashes for folder paths
- Spaces or special characters in path names

![Path Routing Example](images/Fig.41.png)

**Solutions:**
- Use absolute paths when possible
- Verify all paths in Main.jl lines 22-25
- Check scenario sheet name if changed (line 28)

### File Access Problems

**Excel File Locked:**
- Close Excel before running Julia code
- Check if file is open in another program

**CSV Import Issues:**
- Verify Results.xlsx is in correct folder
- Check macro security settings in Excel
- Ensure CSV files are not corrupted

## Next Steps

1. **[Install Required Software](installation.md)** - Complete setup if not done
2. **[Try Examples](Examples.md)** - Run sample scenarios and troubleshooting
3. **[Technical Reference](api.md)** - Detailed specifications and file formats

---

**Ready to optimize!** You now understand the OptiPlant file structure and workflow.