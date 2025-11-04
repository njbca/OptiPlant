# OptiPlant Tool: Files and Usage

This section explains the file structure of OptiPlant and how to use the tool effectively.

## Getting OptiPlant

Download OptiPlant from GitHub:

1. Go to https://github.com/njbca/OptiPlant
2. Click **"Code → Download ZIP"**
3. Extract the ZIP file to your desired location
4. Navigate to the extracted **OptiPlant-master** folder

## File Structure Overview

OptiPlant is organized into two main folders:

### Main Directories

- **BASE**: Contains Data and Results (not code-related)
- **RUN CODE**: Contains the Julia scripts to import data, define scenarios, and run the optimization model

```
OptiPlant-master/
├── BASE/
│   ├── Data/
│   │   ├── Inputs/          # Excel files with plant units, techno-economic data, scenarios
│   │   └── Profiles/        # Excel files with wind/solar profiles and electricity prices
│   └── Results/             # Output folders created per simulation run
│       └── Results.xlsx     # Excel file for visualization
└── RUN CODE/
    ├── ImportData.jl        # Imports input data (units, techno-economics, profiles)
    ├── ImportScenarios.jl   # Imports scenario conditions
    └── Main.jl              # Main optimization model
```

## Run Code Folder

### Contents and Purpose

The **RUN CODE** folder contains three essential Julia scripts:

- **`ImportData.jl`**: Imports into Julia the necessary input data (units, techno-economics, power profiles)
- **`ImportScenarios.jl`**: Imports information regarding the scenario conditions of the study  
- **`Main.jl`**: The optimization model; uses imported data and extracts outputs

### How to Run the Model

1. **Open Main.jl** in VS Code (from RUN CODE folder)

2. **Configure the solver** (line 4):
   ```julia
   solver = "HiGHS"    # or "Gurobi"
   ```

3. **Set directories** (lines 22-25):
   ```julia
   # OptiPlant directory
   OptiPlant_directory = "C:/path/to/OptiPlant-master"
   
   # Input data Excel file name  
   input_data_file = "Input_data_example"
   
   # Input data Excel sheet name
   input_sheet_name = "Data_base_case"
   
   # Results folder name
   results_folder = "Results_base_case"
   ```

4. **Run the file** in VS Code

### Configuration Options

- **Solver selection**: Choose between HiGHS (open-source) or Gurobi (commercial)
- **Path configuration**: Set correct paths to inputs and outputs
- **Scenario sheets**: If you create a new scenarios sheet in the Inputs Excel, ensure Main.jl references it correctly (e.g., line 28)

## Base Folder: Data

### Input Data Structure

The **BASE/Data** folder contains two subfolders:

#### Inputs Subfolder

Contains Excel workbooks (example: `Input_data_example.xlsx`) with standard sheets:

##### Data_base_case Sheet
- **Purpose**: List of possible units (non-electrical and electrical) and characteristics
- **Contents**: 
  - Production rates, heat/electrical flows
  - Load ranges, ramp constraints  
  - CapEx, OpEx parameters
  - **Red box**: Default yearly demands of each fuel (main model drivers)
- **Units and sources**: Indicated for all parameters

##### Selected_units Sheet
- **Purpose**: 1/0 matrix indicating which units/technologies are included per fuel production process
- **Examples**: NH₃, H₂, MeOH configurations
- **Usage**: Set 1/0 according to preference (default represents "standard case")
- **Recommendation**: Work on a copy or keep track of changes

##### Scenarios_definition Sheet  
- **Purpose**: Defines operating strategy and conditions
- **Function**: Logic sits between Data_base_case/Selected_units and outputs
- **Usage**: Useful for sensitivity analysis

##### ScenariosToRun Sheet
- **Purpose**: Lists the scenarios to run
- **Parameters**: Operating strategy, location wind/solar, year, produced fuel, electrolyzer technology
- **Important**: Model stores results as CSV in a folder named per this sheet
- **Critical**: Carefully type names that must match other sheets

##### Sources Sheet
- **Purpose**: References/sources for Data_base_case entries
- **Maintenance**: Should be updated if you change/add input data

#### Profiles Subfolder

Contains Excel files (e.g., `2019.xlsx`) with renewable energy and price data:

##### Flux Sheet
- **Content**: Hourly solar and wind profiles (normalized generator output)
- **Coverage**: Various technologies and locations for the specified year
- **Format**: Normalized values (0-1)

##### Price Sheet  
- **Content**: Hourly grid buy price for the specified year
- **Coverage**: Different locations
- **Units**: Currency per MWh

### Data Requirements and Specifications

#### Profile Sources
- **Wind profiles**: From CorRES tool
- **Solar profiles**: From renewable.ninja website

#### Unit Classification
- **Non-electrical units**: Distinguished from electrical units in inputs
- **Electrical units**: Separate category with different parameters

### How to Prepare Input Data

1. **Data_base_case**: Update only if necessary; units and sources are indicated for parameters

2. **Selected_units**: Set 1/0 according to preference; prefer working on a copy

3. **Scenarios_definition**: Adjust scenario logic relative to inputs for sensitivity analysis

4. **ScenariosToRun**: Carefully type names that must match other sheets; if creating new sheet per study case, ensure sheet name is updated in Main.jl (e.g., line 28)

5. **Sources**: Maintain if inputs are changed

## Base Folder: Results

### Output File Structure

**BASE/Results** contains:
- **Results Excel file**: For visualization and analysis
- **Subfolders per run**: Named according to ScenariosToRun sheet (e.g., "Results_base_case")

Each run folder contains three subfolders:
- **Data used** (CSV files)
- **Hourly results** (CSV files)  
- **Main results** (CSV files)

### Results Interpretation

#### Using the Results Excel File

1. **Setup**:
   - Use the "Results" Excel file 
   - Make a copy and place it into the corresponding run's results folder

2. **Import Process**:
   - Open the "Import" sheet
   - Set correct directories for "Main results folder" and "Hourly results folder" 
   - **Important**: Paths should end with "\"
   - Run macros to import data

3. **View Results**:
   - **Scenario outputs**: Sheets named after scenarios (as in Inputs)
   - **"All_scenarios"**: Shows output values for each unit and scenario
   - **Analysis sheets**: "Elec production", "Electricity consumption", "Production cost", "Cost breakdown", "Installed capacities"
   - **Visualization**: Use Pivot Tables for plotting; refresh pivots after importing new results

#### Additional Result Sheets

When hourly results are imported:
- Each sheet corresponds to a run scenario
- Contains hourly flows for different parameters
- Time-series data for detailed analysis

### Output Units

- **Non-electrical units**: t/h (tonnes per hour)
- **Electrical units**: MW  
- **Hourly flow sheets**: Values are x/1000 (kg/h and kW, respectively)
- **Mass storage**: t (tonnes)
- **Electricity storage**: MWh

### File Formats Generated

All outputs are in **CSV format** for:
- Data used
- Hourly results  
- Main results

### Post-processing Options

- **Primary tool**: Provided "Results" Excel workbook with macros
- **Functionality**: Import CSVs and create Pivot Tables
- **Purpose**: Visualize and analyze results
- **Workflow**: CSV → Excel → Analysis → Visualization

## Best Practices

### File Management
- Keep a copy of standard Inputs to revert changes (especially Selected_units)
- Carefully maintain consistent names across Excel sheets and Main.jl references
- Organize results folders with descriptive names

### Workflow
1. **Prepare data** in Excel (Inputs and Profiles)
2. **Configure** Main.jl with correct paths and solver
3. **Run** the optimization model
4. **Import results** using Results Excel file
5. **Analyze** using Pivot Tables and charts

### Environment Management
- Activate the Julia environment each session
- Use `status` to verify packages are installed
- Refresh Excel Pivot Tables after importing new results

## Next Steps

- **[Examples](Examples.md)** - Practical workflow examples and troubleshooting
- **[API Reference](api.md)** - Technical specifications and file formats
- **[Installation](installation.md)** - Return to installation if needed