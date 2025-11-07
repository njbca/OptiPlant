# Interactive Dashboards - Setup and Usage Guide

This document provides comprehensive instructions for setting up and using the Streamlit-based interactive dashboards included with OptiPlant. These web-based visualization tools offer advanced data exploration capabilities beyond traditional Excel outputs.

## Overview

OptiPlant includes three specialized dashboards for different types of analysis:

- **Dashboard_CO2.py**: Primary scenario comparison tool with location-based grouping
- **Dashboard_Daily.py**: Hourly time series visualization for operational analysis  
- **Dashboard_Scenarios.py**: Multi-scenario comparative analysis across key metrics

## Prerequisites

### Software Requirements
- **Python 3.7+** installed on your system
- **pip** package manager (included with Python)
- **Web browser** (Chrome, Firefox, Safari, or Edge)

### OptiPlant Requirements
- **Completed OptiPlant runs** with CSV results generated
- **Excel scenario metadata files** (for CO2 Dashboard)
- **Proper file structure** as outlined in OptiPlant documentation

## Installation and Setup

### 1. Create Python Virtual Environment

**Windows PowerShell:**
```powershell
# Navigate to OptiPlant directory
cd "C:\path\to\OptiPlant"

# Create virtual environment
python -m venv .venv

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

**macOS/Linux:**
```bash
# Navigate to OptiPlant directory
cd "/path/to/OptiPlant"

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Verify Installation

Check that all required packages are installed:
```bash
pip list
```

Expected packages:
- streamlit
- pandas
- matplotlib
- numpy
- openpyxl
- xlrd

## Dashboard Usage

### CO2 Dashboard (Primary Tool)

**Purpose**: Compare scenarios by location with stacked bar charts grouped by technology type.

**Launch Command:**
```powershell
streamlit run src/PlotGraphs/Dashboard_CO2.py
```

**Key Features:**
- Interactive scenario comparison by location
- Multi-level grouping (Electrolyser → Fuel → Location)
- Stacked bar charts with customizable metrics
- Debug tools for Excel parsing verification

**Data Requirements:**
- CSV result files following pattern: `Scenario_<key>.csv`, `Scenario <key>.csv`, or `Scenario-<key>.csv`
- Excel metadata file with `ScenariosToRun` sheet
- Results directory containing OptiPlant CSV outputs

### Daily Series Dashboard

**Purpose**: Visualize hourly time series data from flow results.

**Launch Command:**
```powershell
streamlit run src/PlotGraphs/Dashboard_Daily.py
```

**Key Features:**
- Hourly time series plotting
- Customizable time range selection (start/end hour)
- Multi-series visualization with clean formatting
- Professional legend positioning and auto-scaled axes

**Data Requirements:**
- Flow CSV files from OptiPlant hourly results
- Directory path to folder containing flow CSVs

### Scenario Comparison Dashboard

**Purpose**: Compare multiple scenarios across key performance metrics.

**Launch Command:**
```powershell
streamlit run src/PlotGraphs/Dashboard_Scenarios.py
```

**Key Features:**
- Multi-scenario comparative analysis
- Technology-specific metric comparison (CAPEX, capacity, etc.)
- Stacked bar visualizations with selective filtering
- Batch processing of scenario CSV files

**Data Requirements:**
- Multiple scenario CSV files in main results folder
- Standardized column naming across scenarios

## Configuration

### Default Paths

Each dashboard includes default configuration paths that you can modify:

**Dashboard_CO2.py:**
```python
DEFAULT_RESULTS_DIR = r"C:\GitHub\OptiPlant.jl\results\Ammonia_paper\Results_base_case\Main results"
DEFAULT_XLSX = r"C:\GitHub\OptiPlant.jl\data\Ammonia_paper\model_inputs\Data_ammonia_paper.xlsx"
```

**Dashboard_Daily.py:**
```python
DEFAULT_FLOWS_FOLDER = r"C:\GitHub\OptiPlant.jl\results\Greenlab\All_fuels_PhD\Hourly results\Flows"
```

**Dashboard_Scenarios.py:**
```python
main_results_folder = "C:\\GitHub\\OptiPlant.jl\\results\\Greenlab\\All_fuels_PhD\\Main results\\"
```

### Customizing Paths

1. **Via Dashboard Interface**: Use sidebar input fields to specify custom paths
2. **Via Code Modification**: Edit the default path variables in each dashboard file
3. **Via Environment Variables**: Set system environment variables (advanced users)

## Troubleshooting

### Common Issues

#### "No result files found"
**Cause**: Incorrect results directory path or missing CSV files.
**Solution**: 
1. Verify the Results directory path in the dashboard sidebar
2. Ensure CSV files follow naming pattern: `Scenario_*.csv`
3. Check that OptiPlant has successfully generated results

#### "Scenario names missing"
**Cause**: Excel metadata parsing issues or incorrect sheet structure.
**Solution**:
1. Expand "Debug: ScenariosToRun detection" section in CO2 Dashboard
2. Verify Excel sheet name is exactly `ScenariosToRun`
3. Check header row detection in debug output

#### "Module not found" errors
**Cause**: Missing Python dependencies or virtual environment not activated.
**Solution**:
1. Ensure virtual environment is activated
2. Reinstall dependencies: `pip install -r requirements.txt`
3. Verify Python version compatibility (3.7+)

#### Dashboard won't load
**Cause**: Port conflicts or Streamlit installation issues.
**Solution**:
1. Try different port: `streamlit run --server.port 8502 dashboard_file.py`
2. Clear Streamlit cache: Delete `.streamlit` folder in home directory
3. Restart terminal and reactivate virtual environment

### File Format Requirements

#### CSV Files (OptiPlant Results)
- Must contain standard OptiPlant output columns
- File names must follow pattern: `Scenario_<identifier>.csv`
- Numeric identifiers are automatically detected and sorted

#### Excel Metadata Files  
- Sheet name must be exactly `ScenariosToRun`
- Headers should include standard scenario parameters
- First few rows may contain metadata (automatically detected)

### Debug Tools

The CO2 Dashboard includes built-in debugging features:

1. **Header Detection Debug**: Shows how Excel headers were parsed
2. **File Pattern Matching**: Displays which CSV files were found and matched
3. **Data Type Detection**: Shows column data types and parsing results

Access debug tools through the expandable "Debug" sections in the dashboard sidebar.

## Advanced Usage

### Custom Visualizations

Dashboards can be extended with custom visualizations by:

1. **Modifying Existing Charts**: Edit Matplotlib/Plotly code sections
2. **Adding New Metrics**: Extend column selection and calculation logic
3. **Custom Grouping**: Modify data aggregation and grouping functions

### Batch Processing

For large scenario sets:

1. **Organize Results**: Use consistent naming and folder structure
2. **Metadata Management**: Maintain comprehensive Excel scenario sheets
3. **Automated Reports**: Consider scripting dashboard generation for regular reporting

### Integration with OptiPlant Workflow

1. **Run OptiPlant**: Complete optimization runs with CSV output enabled
2. **Organize Results**: Ensure proper folder structure and file naming
3. **Launch Dashboards**: Use appropriate dashboard for analysis type
4. **Export Results**: Save dashboard outputs for reports and presentations

## Support and Development

### Getting Help

1. **Check this documentation** for common issues and solutions
2. **Review dashboard source code** in `src/PlotGraphs/` for implementation details
3. **Open GitHub issues** for bugs or feature requests
4. **Consult OptiPlant main documentation** for model-specific questions

### Contributing

Dashboard improvements and new features are welcome:

1. **Fork the repository** and create a feature branch
2. **Test thoroughly** with different data sets and scenarios
3. **Document changes** in code comments and this guide
4. **Submit pull request** with clear description of improvements

---

**Last Updated**: November 2025  
**Version**: Compatible with OptiPlant Development branch
