# Interactive Dashboards - Setup and Usage Guide

## Overview

OptiPlantPtX includes three specialized dashboards for different types of analysis:

- **Dashboard_hourly.py**: Hourly time series visualization for operational analysis  
- **Dashboard_scenarios.py**: Multi-scenario comparative analysis
- **dashboard_impact_categories.py**: Life cycle impact assessment analysis

## Installation and Setup

If you have Python already installed on VS Code you can skip the first two steps.

1- Download and install [Python](https://www.python.org/downloads/).

2 Add the *Python* extension in the code editor (in "Extensions marketplace" on the left sidebar)

3- Open the terminal inside VS Code by clicking Terminal > New Terminal. Make sure that you are located in the OptiPlant folder. Run the following command to create an environment ``.venv``:

```bash
python -m venv .venv
```
4- Activate the environment writting in the terminal

```bash
.venv\Scripts\Activate.ps1
```

**Note** (from [here](https://docs.python.org/3/library/venv.html))

On Microsoft Windows, it may be required to enable the Activate.ps1 script by setting the execution policy for the user. You can do this by issuing the following PowerShell command:

```bash
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

5- Install the required dependencies

```bash
python -m pip install -r requirements.txt
```
6- Change the default result folder on top of the dashboard python scripts to your own (in the result_analysis_dashboards folder): 

```python
main_results_folder = Path.cwd() / "results" / "Example" / "Your_folder_name" / "Main results"
```

7- Launch the required data dashboards from powershell:

```bash
python -m streamlit run result_analysis_dashboards/dashboard_scenarios.py
python -m streamlit run result_analysis_dashboards/dashboard_hourly.py
python -m streamlit run result_analysis_dashboards/dashboard_impact_categories.py
```
