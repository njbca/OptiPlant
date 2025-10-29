# Dashboards — how to run and troubleshoot

This document explains how to run the Streamlit dashboards bundled in
`src/PlotGraphs/` and how to troubleshoot the common Excel/CSV parsing issues.

Quick start (Windows PowerShell)

1. Create a Python virtual environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Run the CO2 dashboard:

```powershell
streamlit run src/PlotGraphs/Dashboard_CO2.py
```

Important notes

- The dashboard reads scenario metadata from an Excel file. By default this is
  the file path defined in `DEFAULT_XLSX` inside `Dashboard_CO2.py`.
- The Excel sheet name expected is `ScenariosToRun`. The dashboard attempts to
  detect the header row automatically; if it fails, open the debug expander in
  the Streamlit UI to see the detected header row and the raw rows used for
  detection.
- Scenario CSV file names must follow one of these patterns (case-sensitive):
  `Scenario_<key>.csv`, `Scenario <key>.csv`, or `Scenario-<key>.csv`. The
  dashboard tries numeric coercion when keys look like numbers.

Troubleshooting

- If the dashboard shows "No result files found", verify the `Results directory`
  path in the sidebar points to the folder containing `Scenario_*.csv` files.
- If scenario names are missing, expand the "Debug: ScenariosToRun detection"
  section to see how the Excel sheet was parsed and which header row was used.

If you encounter a CSV/Excel format not handled by the dashboard, paste the
first 10 rows of the `ScenariosToRun` sheet here (or attach the file) and we
can update the detection heuristics.
