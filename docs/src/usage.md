# OptiPlant Tool: Files

## Overview

### General File Structure Explanation

![OptiPlant File Structure](images/Fig.15.png)
*Figure 15: Overall folder structure after extracting the OptiPlant-master ZIP*

**Main folders:**
- **BASE**: Contains Data and Results (not code-related)
- **RUN CODE**: Contains the Julia scripts to import data, define scenarios, and run the optimization model

### Project Organization

**BASE/Data:**
- **Inputs** (Excel files with plant units, techno-economic data, scenarios)
- **Profiles** (Excel files with wind/solar profiles and electricity prices by year)

**BASE/Results:**
- A separate results folder is created per simulation run; folder name set in Inputs → ScenariosToRun
- Each results folder contains subfolders "Data used", "Hourly results", and "Main results"

**RUN CODE:**
- ImportData.jl, ImportScenarios.jl, Main.jl

### Main Directories Purpose

- **RUN CODE**: Core execution scripts and optimization model
- **BASE/Data**: All input data and profiles used by the model
- **BASE/Results**: Outputs produced by model runs, plus a "Results" Excel file for visualization

## Run Code Folder

### Contents and Purpose

![RUN CODE Contents](images/Fig.35.png)
*Figure 35: RUN CODE folder contents (three scripts)*

- **ImportData.jl**: Imports into Julia the necessary input data (units, techno-economics, power profiles)
- **ImportScenarios.jl**: Imports information regarding the scenario conditions of the study
- **Main.jl**: The optimization model; uses imported data and extracts outputs

### Main Execution Files

**Main.jl** is the primary file to run the optimization under most cases.

### How to Run the Model

1. Open Main.jl (Run Code folder) in VS Code
2. Set the solver on line 4 to "HiGHS" or "Gurobi" (you may customize solver)

![Solver Selection](images/Fig.36.png)
*Figure 36: Screenshot showing solver selection (line 4)*

3. Set directories on lines 22–25: OptiPlant directory, input data Excel file name, input data Excel sheet name, and the folder name inside "Results" where outputs will be saved

![Directory Configuration](images/Fig.37.png)
*Figure 37: Screenshot showing directories (lines 22–25) fields in Main.jl*

4. Edit code if necessary; run the file

### Configuration Options

- **Solver selection** (HiGHS or Gurobi)
- **Paths configuration** to inputs and outputs
- If you create a new scenarios sheet in the Inputs Excel, ensure Main.jl references it correctly (e.g., line 28)

## Base Folder: Data

### Input Data Structure

**Inputs subfolder** (Excel workbooks; example: "Input_data_example")

![Inputs Folder](images/Fig.16.png)
*Figure 16: Inputs folder*

**Standard sheets inside an Inputs Excel:**

#### Data_base_case Sheet

![Data_base_case Sheet](images/Fig.17.png)
*Figure 17: Data_base_case sheet with highlighted default yearly demands (red box)*

List of possible units (non-electrical and electrical) and characteristics (production rates, heat/electrical flows, load ranges, ramp constraints, CapEx, OpEx, etc.). Red box indicates default yearly demands of each fuel (main model drivers).

![Unit Parameters](images/Fig.18.png)
*Figure 18: Many parameters with units and sources*

#### Selected_units Sheet

![Selected_units Sheet](images/Fig.19.png)
*Figure 19: Selected_units sheet (1/0 selections)*

1/0 matrix indicating which units/technologies are included per fuel production process (e.g., NH3, H2, MeOH).

#### Scenarios_definition Sheet

![Scenarios_definition Sheet](images/Fig.20.png)
*Figure 20: Scenarios_definition sheet (intermediate logic)*

Defines operating strategy and conditions; logic sits between Data_base_case/Selected_units and outputs; useful for sensitivity analysis.

#### ScenariosToRun Sheet

![ScenariosToRun Sheet](images/Fig.21.png)
*Figure 21: ScenariosToRun sheet (scenario list and parameters)*

Lists the scenarios to run (operating strategy, location wind/solar, year, produced fuel, electrolyzer technology, etc.). The model stores results as CSV in a folder named per this sheet.

#### Sources Sheet

![Sources Sheet](images/Fig.22.png)
*Figure 22: Sources sheet (data references)*

References/sources for Data_base_case entries; should be updated if you change/add input data.

### File Formats Used

Excel (.xlsx) for Inputs and Profiles.

### How to Prepare Input Data

- Update **Data_base_case** only if necessary; units and sources are indicated for parameters
- In **Selected_units**, set 1/0 according to preference (default represents "standard case"). Prefer working on a copy or keep track of changes
- In **Scenarios_definition**, adjust scenario logic relative to inputs for sensitivity analysis
- In **ScenariosToRun**, carefully type names that must match other sheets; if you create a new sheet per study case, ensure the sheet name is updated in Main.jl (e.g., line 28)
- Maintain **Sources** sheet if inputs are changed

### Data Requirements and Specifications

**Profiles subfolder** (e.g., "2019.xlsx") has:

![Profiles Folder](images/Fig.23.png)
*Figure 23: Profiles folder*

![2019 Workbook](images/Fig.24.png)
*Figure 24: 2019 workbook*

#### Flux Sheet

![Flux Sheet](images/Fig.25.png)
*Figure 25: Flux sheet (normalized wind/solar power profiles)*

Hourly solar and wind profiles (normalized generator output) for various technologies and locations in the specified year.

#### Price Sheet

![Price Sheet](images/Fig.26.png)
*Figure 26: Price sheet (hourly electricity prices)*

Hourly grid buy price for the specified year at different locations.

**Profile sources:**
- **Wind profiles** from CorRES tool
- **Solar profiles** from renewable.ninja website

**Units:** Non-electrical vs electrical units are distinguished in inputs.

## Base Folder: Results

### Output File Structure

![Results Folder Structure](images/Fig.27.png)
*Figure 27: Results folder structure*

BASE/Results contains a "Results" Excel file and subfolders per run (e.g., "Results_base_case").

![Results Subfolders](images/Fig.28.png)
*Figure 28: Example of subfolders ("Data used", "Hourly results", "Main results")*

Each run folder contains:
- **Data used** (CSV)
- **Hourly results** (CSV)  
- **Main results** (CSV)

### Results Interpretation

![Results Excel File](images/Fig.29.png)
*Figure 29: Results Excel file*

Use the "Results" Excel file (make a copy and place it into the corresponding run's results folder).

![Results File Placement](images/Fig.30.png)
*Figure 30: Placement within the run folder*

#### Import Sheet

![Import Sheet](images/Fig.31.png)
*Figure 31: Import sheet showing directories and macro buttons*

In the "Import" sheet, set correct directories for "Main results folder" and "Hourly results folder" (paths should end with "\") and run macros to import.

#### Analysis Sheets

![All_scenarios Sheet](images/Fig.32.png)
*Figure 32: "All_scenarios" sheet displaying outputs per unit and scenario*

View scenario outputs in sheets named after scenarios (as in Inputs). "All_scenarios" shows output values for each unit and scenario.

![Analysis Charts](images/Fig.33.png)
*Figure 33: Example Pivot Table/chart (e.g., production, consumption, cost, capacities)*

Other sheets (e.g., "Elec production", "Electricity consumption", "Production cost", "Cost breakdown", "Installed capacities") provide breakdowns and allow plotting via Pivot Tables. Refresh pivots after importing new results.

![Hourly Results Sheet](images/Fig.34.png)
*Figure 34: Example hourly results sheet with time-series flows*

Additional sheets appear when hourly results are imported; each corresponds to a run scenario with hourly flows for different parameters.

### Units for Outputs

- **Non-electrical units**: t/h (tonnes per hour)
- **Electrical units**: MW
- **Hourly flow sheets**: values are x/1000 (kg/h and kW, respectively)
- **Mass storage**: t (tonnes)
- **Electricity storage**: MWh

### File Formats Generated

CSV files for Data used, Hourly results, and Main results.

### Post-processing Options

Use the provided "Results" Excel workbook with macros to import CSVs and Pivot Tables to visualize and analyze results.

## Best Practices

- Keep a copy of standard Inputs to revert changes (especially Selected_units)
- Carefully maintain consistent names across Excel sheets (ScenariosToRun, etc.) and Main.jl references
- Activate the Julia environment each session; use "status" to verify packages
- Refresh Excel Pivot Tables after importing new results

## Next Steps

1. **[Complete Installation](installation.md)** - Set up Julia, VS Code, and packages
2. **[Learn Troubleshooting](Examples.md)** - Common issues and solutions  
3. **[Technical Details](api.md)** - Detailed specifications